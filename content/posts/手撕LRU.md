---
title: "手撕LRU（Go语言版本）" 
subtitle: ""
date: 2025-08-27
draft: false
tags: ["算法", ""]
keywords: ["LRU", "Go"]
showFullContent: false
author: "Orion Young"
description: "LRU的Go实现版本（力扣型核心代码）"
hideComments: false
toc: true
cover: ""
readingTime: false
---





## 1.使用container/list实现

> 首先，我们要了解标准库中的双向链表list

### 标准库list详解

> list.go源文件https://cs.opensource.google/go/go/+/refs/tags/go1.24.2:src/container/list/list.go

在 Go 语言的 `container/list` 包中，`Element` 结构体代表双向链表中的一个节点。该结构体的定义以及相关字段的用途如下：

```go
type Element struct {
    // 指向前一个和后一个元素的指针
    next, prev *Element

    // 指向该元素所在链表的指针
    list *List

    // 存储在该元素中的值
    Value interface{}
}
```

下面详细解释 `Element` 结构体的各个字段：

1. `next` 和 `prev`

- 类型为 `*Element`，也就是指向 `Element` 结构体的指针。
- `next` 指向链表中的下一个元素，`prev` 指向链表中的前一个元素。借助这两个指针，链表能够实现双向遍历。

2. `list`

- 类型为 `*List`，即指向 `List` 结构体的指针。
- 此指针指向该元素所在的链表，其作用在于确保元素和链表之间的关联，并且在对元素进行操作时，能够保证操作的正确性。

3. `Value`

- 类型为 `interface{}`，这意味着它能够存储任意类型的值。
- 该字段用于存放用户在链表节点中存储的数据。

Element定义了`Next()`和`Prev()`方法，定义如下：

```go
// Next returns the next list element or nil.
func (e *Element) Next() *Element {
    if p := e.next; e.list != nil && p != &e.list.root {
        return p
    }
    return nil
}

// Prev returns the previous list element or nil.
func (e *Element) Prev() *Element {
    if p := e.prev; e.list != nil && p != &e.list.root {
        return p
    }
    return nil
}
```

总的来说，这两个方法的执行逻辑是：

- 如果该元素在某一个链表上，且其前一个（后一个）元素不是链表的根元素，则返回其前一个（后一个）元素
- 其它情况下，即如果该元素不属于任何链表，或者其前一个（后一个）元素为链表的根元素，则返回`nil`（即：链表的根元素只起到一个占位作用，而并不会存储数据值）

### 初始化链表

我们可以通过调用`list.New()`函数或者直接声明一个`list.List`类型的变量来初始化一个链表：

```go
// 方法一：使用list.New()函数
l := list.New()

// 方法二：直接声明一个list.List变量
var l list.List
```

## 基本操作

### 添加元素

`container/list`包提供了多种方法来向链表中添加元素：

- • `PushFront(v interface{}) *Element`：在链表的头部插入一个元素，返回该元素的指针。
- • `PushBack(v interface{}) *Element`：在链表的尾部插入一个元素，返回该元素的指针。
- • `InsertBefore(v interface{}, mark *Element) *Element`：在指定元素之前插入一个新元素。
- • `InsertAfter(v interface{}, mark *Element) *Element`：在指定元素之后插入一个新元素。

```go
l := list.New()
l.PushBack("Go")
l.PushFront(42)
e := l.PushBack(3.14)
l.InsertBefore("before", e)
l.InsertAfter("after", e)
```

### 删除元素

可以使用`Remove`方法删除链表中的元素，`Remove`方法接受一个指向链表元素的指针，删除该元素并返回其值：

```go
l := list.New()
e := l.PushBack("to be removed")
l.Remove(e)
```

### 遍历链表

可以使用`Front()`和`Back()`方法获取链表的第一个和最后一个元素，然后通过元素的`Next()`和`Prev()`方法进行遍历：

```go
// 从前向后遍历
for e := l.Front(); e != nil; e = e.Next() {
    fmt.Println(e.Value)
}

// 从后向前遍历
for e := l.Back(); e != nil; e = e.Prev() {
    fmt.Println(e.Value)
}
```

## 链表的特性

- • **双向链表**：每个节点有两个指针，分别指向前一个节点和后一个节点。
- • **O(1)时间复杂度的插入和删除**：链表的插入和删除操作都只需要调整指针，因此效率很高。
- • **遍历效率较低**：由于链表节点不连续存储，无法利用CPU缓存，遍历效率相对于数组较低。

## 常见应用场景

1. 1. **需要频繁插入和删除操作的场景**：由于链表插入和删除操作的时间复杂度为O(1)，在需要频繁进行这些操作时，链表表现优异。
2. 2. **实现LRU缓存**：链表和哈希表的结合可以高效实现LRU（最近最少使用）缓存。
3. 3. **队列和双端队列**：链表可以方便地实现FIFO队列和双端队列。

### 代码实现

```go
import "container/list"

type LRUCache struct {
    Cap int
    Keys map[int]*list.Element // element.Value放的是pair
    List *list.List
}

type Pair struct {
    k, v int
}

func Constructor(capacity int) LRUCache {
    return LRUCache{
        Cap: capacity,
        Keys: make(map[int]*list.Element),
        List: list.New(),
    }
}

func (this *LRUCache) Get(key int) int {
    // 命中要把key放链表头
    if elmt, exists := this.Keys[key]; exists {
        this.List.MoveToFront(elmt)
        return elmt.Value.(Pair).v // elmt是结点，结点里面有数据域Value，是一个pair
    }

    return -1
}

func (this *LRUCache) Put(key int, value int)  {
    // 链表头插入
    if elmt, exists := this.Keys[key]; exists {
        // 存在，更新值
        elmt.Value = Pair{k: key, v: value}
        this.List.MoveToFront(elmt)
    }else{
        // 不存在
        newElmt := this.List.PushFront(Pair{k: key, v: value})
        this.Keys[key] = newElmt
    }
    if this.List.Len() > this.Cap {
            lastElmt := this.List.Back()
            this.List.Remove(lastElmt)
            // 使用 lastElmt 来删除 Keys 中的键
            delete(this.Keys, lastElmt.Value.(Pair).k)
    }
}

/**
 * Your LRUCache object will be instantiated and called as such:
 * obj := Constructor(capacity);
 * param_1 := obj.Get(key);
 * obj.Put(key,value);
 */
```

![手撕LRU](http://img.orionyoung.com/pic/手撕LRU.png)

想要O1存取，一定要借助map，先查map，map{key，指向链表结点的指针}，链表又包含四个元素{1.prev，2.next，3.pair{key，val}，4.this.List}

结点为什么还要存一个键值对pair，存个val不就行了吗？

- pair是为了删除元素服务的。
- 如果没有pair，超过容量cap时，我们要删去队列尾部进程，我们要删两个地方，一个是map，一个是链表尾结点，流程是删去结点，再删map[key]，链表结点里面只有val，没有key，删去后我们我们要遍历map找哪个key对应element的val，这是On复杂度
- 如果有pair，删去结点时，我们能得到pair{key, val}，这样拿着key进行O1复杂度的map删除
- 不能先删map！若先从 `map` 里删除键值对，再去删除链表节点，在删除链表节点的过程中要是出现异常（例如链表操作逻辑出错、内存错误等），那么 `map` 里对应的键值对已被删除，可链表节点却还存在，这就会造成数据不一致。在 LRU 缓存里，链表节点和 `map` 中的键值对是相互关联的。若先删除 `map` 中的键值对，后续再删除链表节点时，就难以依据 `map` 快速定位到要删除的链表节点，因为 `map` 里已经没有对应的映射信息了。