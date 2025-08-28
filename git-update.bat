@echo off
echo 开始执行 Git 提交和推送操作...

:: 检查是否在 Git 仓库目录中
if not exist .git (
    echo 错误：当前目录不是 Git 仓库，请在项目根目录运行此脚本
    pause
    exit /b 1
)

:: 添加所有更改
echo 正在执行 git add . ...
git add .
if %errorlevel% neq 0 (
    echo 错误：git add 执行失败
    pause
    exit /b %errorlevel%
)

:: 提交更改
echo 正在执行 git commit...
git commit -m "Update blog content"
if %errorlevel% neq 0 (
    echo 错误：git commit 执行失败（可能没有需要提交的更改）
    pause
    exit /b %errorlevel%
)

:: 推送到远程仓库
echo 正在执行 git push...
git push origin main
if %errorlevel% neq 0 (
    echo 错误：git push 执行失败
    pause
    exit /b %errorlevel%
)

echo 操作完成！所有更改已提交并推送到远程仓库
pause
