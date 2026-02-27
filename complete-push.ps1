# Complete git rebase and push
$env:GIT_EDITOR = 'echo'
$env:EDITOR = 'echo'

# Continue rebase with no-edit flag
git -c core.editor=true rebase --continue --no-edit

if ($LASTEXITCODE -eq 0) {
    Write-Host "Rebase completed successfully"
    
    # Push to origin
    git push origin Tharuka --force-with-lease
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Push completed successfully!"
    }
    else {
        Write-Host "Push failed. You may need to force push."
    }
}
else {
    Write-Host "Rebase failed. Status:"
    git status
}
