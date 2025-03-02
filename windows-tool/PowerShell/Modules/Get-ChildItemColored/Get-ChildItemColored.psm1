####
#  get-ChildItemColored.psm1
#  
#  Linux/Coreutils-style 'ls' for Powershell;
#  Inspired by Get-ChildItemColor by Tojo2000 <tojo2000@tojo2000.com>;
#  Written by Brandon Dowell.
#  https://la11111.wordpress.com/2012/10/20/code-coreutils-style-ls-for-windows-powershell/
#
#  Unlike other similar scripts which simply colorize the output of built-in get-childitem, thus preserving
#  the objects it outputs, I just wanted a nice human-friendly way to view files. This script uses write-host
#  for output, thus disabling that feature. Use 'dir' if you need to pipe the output somewhere.
#
#  colors are fully customizable through your profile.ps1. Output is meant to mimic coreutils ls.
#
#  to install, create a directory in your module path somewhere called 
# 'get-ChildItemColored' and place this file inside.
#  the default module directory is:
#  c:\users\your_username\Documents\WindowsPowerShell\modules
#  
#  Below this file, I'll include an example of what you should add to your profile.ps1.
#
#  enjoy 🙂
###

function get-width { param([array]$a)
	$w = 0
	$a | %{ 
		if ($_.name.length -gt $w) {
			$w = $_.name.length
		}
	}
	$w += 2 # space between columns; allow for / jewelry
	return $w
}

function make-cols { param([array]$files, $cols)
	$col_data = @()

	$rows = [math]::ceiling($files.count/$cols)
	$full_cols = [math]::floor($files.count/$rows)
	$leftovers = $files.count%$rows
	
	if ($leftovers -gt 0) {
		$total_cols = $full_cols + 1
	} else {
		$total_cols = $full_cols
	}

	foreach ($i in 0..($total_cols–1)) {
		$li = $rows * $i
		if (($total_cols -gt $full_cols ) -and (($i+1) -eq $total_cols)) { 
			$ui = $files.count – 1
		} else {
			$ui = ($rows * ($i + 1))-1
		}
		$this_col = new-object psobject
		$this_col | add-member noteproperty "files" @()
		$this_col.files += $files[$li..$ui]
		$this_col | add-member noteproperty "width" $(get-width($this_col.files))
		$col_data += $this_col
	}
	$col_data
}

function find-bestfit { param([array]$files)
	$max_width = get-width $files
	$try_cols = [math]::floor($term_width/$max_width)
	$foundbestfit = $false
	$cols = @()
	$cols += make-cols –files $files –cols $try_cols
	while (!$foundbestfit) {
		$combined_width = 0
		foreach ($c in $cols) {
			$combined_width += $c.width
		}
		if ($combined_width -gt $term_width) {
			$try_cols -= 1 #not tested, could harbor bugs
			$foundbestfit = $true
		} elseif (($term_width – $combined_width) -gt $max_width) {
			if ($cols.count -lt $try_cols) {
				$foundbestfit = $true
			} else {
				$try_cols += 1
			}
		} else {
			$foundbestfit = $true
		}
		$cols = @()
		$cols += make-cols –files $files –cols $try_cols
	}
	return $cols
}

function pick-color { param($file)
	if ($file.GetType().Name -eq 'DirectoryInfo') {
		if ($global:lscolor_dir) {
			$global:lscolor_dir
		} else {
			return $directory
		}
	} else {
		foreach($c in $config ) {
			if ($c.regex.IsMatch($file.Name)) {
				return $c.color
			} 
		}
		$Host.UI.RawUI.ForegroundColor
	}
}

function write-columns { param([array]$cols)
	write-host
	foreach ($r in 0..($cols[0].files.count – 1)) {
		foreach ($c in $cols) {
			$f = $c.files[$r]
			if ($f) {
				$dec = 0
				$fn = $f.name
				if ($f.GetType().Name -eq 'DirectoryInfo') {
					$fn += "/"
				}
				if ($f.Attributes -match "Hidden") {
					$dec += 1
					if ($global:lscolor_hidden) {
						$hidden = $global:lscolor_hidden
					}
					if ($global:lscolor_hidden_bg) {
						$hidden_bg = $global:lscolor_hidden_bg	
					}
					write-host –fore $hidden –back $hidden_bg –nonewline "$fn"
					write-host –nonewline "$(' '*($c.width – $fn.length – $dec))"
				} else {
					write-host –nonewline –fore $(pick-color $f) "$fn$(' '*($c.width – $fn.length – $dec))"
				}
			} 
		}
		write-host
	}
	write-host
}

function Get-ChildItemColored {param($Path, [switch]$Force)
	$regex_opts = ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
	-bor [System.Text.RegularExpressions.RegexOptions]::Compiled)
	$config = @()
	
	if ($global:lscolor_userdef) {
		$global:lscolor_userdef | % {
			$re = New-Object System.Text.RegularExpressions.Regex($_.get_item('regex'), $regex_opts)
			$o = new-object psobject
			$o | add-member noteproperty "regex" $re
			$o | add-member noteproperty "color" $_.get_item('color')
			$config += $o
		}
	}
	
	#default_config 
	$directory = 'DarkCyan'
	$hidden = 'DarkRed'
	$hidden_bg = 'DarkGray'
	@(
		@{ #compressed
			"regex" = '\.(zip|tar|gz|rar|7z|bz2|tgz|tcz)$';
			"color" = "Red";
		}, 
		@{ #script/executable
			"regex" = '\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg|fsx|msi|sh)$';
			"color" = "Green";
		},
		@{ #images
			"regex" = '\.(jpg|jpeg|gif|png|tif|bmp|svg|xcf|psd)$';
			"color" = "Magenta";
		},
		@{ #backup files
			"regex" = '(\.bak|~)$';
			"color" = "DarkGray";
		},
		@{ #backup files 2 / linux hidden dotfiles
			"regex" = '^(~|\.)';
			"color" = "DarkGray";
		}
	) | % {
		$re = New-Object System.Text.RegularExpressions.Regex($_.get_item('regex'), $regex_opts)
		$o = new-object psobject
		$o | add-member noteproperty "regex" $re
		$o | add-member noteproperty "color" $_.get_item('color')
		$config += $o
	}
	
	$term_width = $host.UI.RawUI.BufferSize.width
	$files = @()
	#$files += invoke-expression ("get-childitem $args")
        # doesn't work if there's paren's in the dir name … ideas??

        if (!($path)) {
		$path = "."
	}
	
	if ($force) {
		$files += get-childitem –force –path $path
	} else { 
		$files += get-childitem –path $path
	}

	if (!($files)) { 
		return
	} else {
		$cols = find-bestfit $files
		write-columns $cols
		#return $files
	}
}
export-modulemember –function get-childitemcolored
