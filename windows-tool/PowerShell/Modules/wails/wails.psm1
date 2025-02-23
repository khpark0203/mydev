$wailsCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $tokens = $commandAst.Extent.Text.Trim() -split "\s+"

    $completions = switch ($tokens[1]) {
        "build" { break }
        "dev" { break }
        "doctor" { break }
        "init" { break }
        "update" { break }
        "show" { break }
        "generate" { break }
        "version" { break }
        
        default {
            "build"
            "dev"
            "doctor"
            "init"
            "update"
            "show"
            "generate"
            "version"
        }
    }

    $completions | Where-Object {$_ -like "${wordToComplete}*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
    }
}

Register-ArgumentCompleter -CommandName wails -Native -ScriptBlock $wailsCompleter