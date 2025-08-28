@echo off
echo begin Git commit...

:: 检查是否在 Git 仓库目录中
if not exist .git (
    echo error, there is not github
    pause
    exit /b 1
)

:: 添加所有更改
echo now git add -ing. ...
git add .
if %errorlevel% neq 0 (
    echo error：git add faied
    pause
    exit /b %errorlevel%
)

:: 提交更改
echo now git commit -ing...
git commit -m "Update blog content"
if %errorlevel% neq 0 (
    echo error：git commit faied
    pause
    exit /b %errorlevel%
)

:: 推送到远程仓库
echo now git push -ing...
git push origin main
if %errorlevel% neq 0 (
    echo error：git push faied
    pause
    exit /b %errorlevel%
)

echo commit success! all changes have saved!
pause
