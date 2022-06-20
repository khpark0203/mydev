$goCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $tokens = $commandAst.Extent.Text.Trim() -split "\s+"

    $completions = switch ($tokens[1]) {
        "bug" {
            break
        }
        "build" {
            break
        }
        "clean" {
            break
        }
        "doc" {
            break
        }
        "env" {
            break
        }
        "fix" {
            break
        }
        "fmt" {
            break
        }
        "generate" {
            break
        }
        "get" {
            switch ($tokens[2]) {
                "github.com/" {
                    break
                }
                "golang.org/" {
                    break
                }

                default {
                    "github.com/"
                    "golang.org/"
                }
            }

            break
        }
        "install" {
            switch ($tokens[2]) {
                "github.com/" {
                    break
                }
                "golang.org/" {
                    break
                }
                
                default {
                    "github.com/"
                    "golang.org/"
                }
            }

            break
        }
        "list" {
            break
        }
        "mod" {
            switch ($tokens[2]) {
                "download" {
                    break
                }
                "edit" {
                    break
                }
                "graph" {
                    break
                }
                "init" {
                    break
                }
                "tidy" {
                    break
                }
                "vendor" {
                    break
                }
                "verify" {
                    break
                }
                "why" {
                    break
                }

                default {
                    "download"
                    "edit"
                    "graph"
                    "init"
                    "tidy"
                    "vendor"
                    "verify"
                    "why"
                }
            }
            break
        }
        "work" {
            break
        }
        "run" {
            break
        }
        "test" {
            break
        }
        "tool" {
            break
        }
        "version" {
            break
        }
        "vet" {
            break
        }
        "help" {
            switch ($tokens[2]) {
                "bug" {
                    break
                }
                "build" {
                    break
                }
                "clean" {
                    break
                }
                "doc" {
                    break
                }
                "env" {
                    break
                }
                "fix" {
                    break
                }
                "fmt" {
                    break
                }
                "generate" {
                    break
                }
                "get" {
                    break
                }
                "install" {
                    break
                }
                "list" {
                    break
                }
                "mod" {
                    break
                }
                "work" {
                    break
                }
                "run" {
                    break
                }
                "test" {
                    break
                }
                "tool" {
                    break
                }
                "version" {
                    break
                }
                "vet" {
                    break
                }
                "buildconstraint" {
                    break
                }
                "buildmode" {
                    break
                }
                "c" {
                    break
                }
                "cache" {
                    break
                }
                "environment" {
                    break
                }
                "filetype" {
                    break
                }
                "go.mod" {
                    break
                }
                "gopath" {
                    break
                }
                "gopath-get" {
                    break
                }
                "goproxy" {
                    break
                }
                "importpath" {
                    break
                }
                "modules" {
                    break
                }
                "module-get" {
                    break
                }
                "module-auth" {
                    break
                }
                "packages" {
                    break
                }
                "private" {
                    break
                }
                "testflag" {
                    break
                }
                "testfunc" {
                    break
                }
                "vcs" {
                    break
                }

                default {
                    "bug"
                    "build"
                    "clean"
                    "doc"
                    "env"
                    "fix"
                    "fmt"
                    "generate"
                    "get"
                    "install"
                    "list"
                    "mod"
                    "work"
                    "run"
                    "test"
                    "tool"
                    "version"
                    "vet"
                    "buildconstraint"
                    "buildmode"
                    "c"
                    "cache"
                    "environment"
                    "filetype"
                    "go.mod"
                    "gopath"
                    "gopath-get"
                    "goproxy"
                    "importpath"
                    "modules"
                    "module-get"
                    "module-auth"
                    "packages"
                    "private"
                    "testflag"
                    "testfunc"
                    "vcs"
                }
            }

            break
        }
        
        default {
            "bug"
            "build"
            "clean"
            "doc"
            "env"
            "fix"
            "fmt"
            "generate"
            "get"
            "install"
            "list"
            "mod"
            "work"
            "run"
            "test"
            "tool"
            "version"
            "vet"
            "help"
        }
    }

    $completions | Where-Object {$_ -like "${wordToComplete}*"} | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
    }
}

Register-ArgumentCompleter -CommandName go -Native -ScriptBlock $goCompleter