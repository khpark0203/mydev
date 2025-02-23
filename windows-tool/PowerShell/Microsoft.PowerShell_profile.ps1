Import-Module posh-git
Import-Module winget
Import-Module DockerCompletion
Import-Module kubectl
Import-Module minikube
Import-Module ssh
Import-Module gocomplete
Import-Module wails
Import-Module aws

#Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionSource None

Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineKeyHandler -Key ctrl+d -ScriptBlock {
    $line=$null
    $cursor=$null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($line -eq "") {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("exit")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::DeleteChar()
    }
}
Set-PSReadlineKeyHandler -Key ctrl+shift+l -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::CancelLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cls")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

Set-Alias ifconfig ipconfig
Set-Alias grep findstr
Set-Alias apidoc apidoc.cmd
Set-Alias xv clip.exe
Set-Alias o Out-String
Set-Alias ex explorer
Set-Alias reboot Restart-Computer
Set-Alias poweroff Stop-Computer

Function cmdpowersaving {shutdown /h}
Set-Alias powersaving cmdpowersaving

Remove-Item Alias:ls -Force


Set-Alias curl curl.exe
Set-Alias which where.exe

Function cmdsd {ssh sub-dev}
Set-Alias sd cmdsd

Function cmdna {explorer .}
Set-Alias na cmdna

Function cmdcdssh {cd $HOME\.ssh}
Set-Alias cdssh cmdcdssh

Remove-Item Alias:pwd
Function cmdpwd {(Get-Item -Path ".").FullName}
Set-Alias pwd cmdpwd

Remove-Item Alias:cd
Function cmdcd {
    if ($args[0] -eq '-') {
        $MYPWD=$OLDPWD
    } elseif ($args[0] -eq $null) {
        $MYPWD=$HOME
    } else {
        $MYPWD=$args[0]
    }
    $tmp=Get-Location
    if ($MYPWD) {
        Set-Location $MYPWD
    }
    Set-Variable -Name OLDPWD -Value $tmp -Scope global
}

Set-Alias cd cmdcd

Function cmdcdcus {cd D:\custom-command}
Set-Alias cdcustomcommand cmdcdcus
Function cmdcdkhpark0203 {cd D:\github\khpark0203}
Set-Alias cdkhpark0203 cmdcdkhpark0203

Function cmdcdgithub {cd D:\github}
Set-Alias cdgithub cmdcdgithub
Set-Alias xc Set-Clipboard
Set-Alias vi vim
Set-Alias hae hae.rdp

Function cmdgb {git branch}
Set-Alias b cmdgb

Function cmdgp {git pull}
Set-Alias p cmdgp

$sshconfig="$HOME\.ssh\config"
Set-Alias gk tgit

Function cmdmlist {mstsc /l}
Set-Alias mlist cmdmlist

Set-Alias k kubectl
Set-Alias mk minikube
Set-Alias dk docker

Remove-Item Alias:sl -Force
Remove-Item Alias:pwd
Remove-Item Alias:cp -Force
Remove-Item Alias:diff -Force
Remove-Item Alias:echo -Force
Remove-Item Alias:sleep -Force
Remove-Item Alias:sort -Force
Remove-Item Alias:tee -Force


Function cmdl {ls.exe -CF $args}
Function cmdla {ls.exe -A $args}
Function cmdlh {ls.exe -lh $args}
Function cmdlha {ls.exe -lha $args}
Function cmdll {ls.exe -l $args}
Function cmdlla {ls.exe -la $args}
Function cmdllh {ls.exe -lha $args}

Set-Alias ls ls.exe
Set-Alias l cmdl
Set-Alias la cmdla
Set-Alias lh cmdlh
Set-Alias lha cmdlha
Set-Alias ll cmdll
Set-Alias lla cmdlla
Set-Alias llh cmdllh
Set-Alias ar ar.exe
Set-Alias arch arch.exe
Set-Alias ascii ascii.exe
Set-Alias ash ash.exe
Set-Alias awk awk.exe
Set-Alias base32 base32.exe
Set-Alias basename basename.exe
Set-Alias bash bash.exe
Set-Alias bc bc.exe
Set-Alias bunzip2 bunzip2.exe
Set-Alias busybox busybox.exe
Set-Alias bzcat bzcat.exe
Set-Alias bzip2 bzip2.exe
Set-Alias cal cal.exe
Set-Alias chattr chattr.exe
Set-Alias chmod chmod.exe
Set-Alias cksum cksum.exe
Set-Alias clear clear.exe
Set-Alias cmp cmp.exe
Set-Alias comm comm.exe
Set-Alias cp cp.exe
Set-Alias cpio cpio.exe
Set-Alias crc32 crc32.exe
Set-Alias cut cut.exe
Set-Alias date date.exe
Set-Alias dc dc.exe
Set-Alias dd dd.exe
Set-Alias df df.exe
Set-Alias diff diff.exe
Set-Alias dirname dirname.exe
Set-Alias dos2unix dos2unix.exe
Set-Alias dpkg-deb dpkg-deb.exe
Set-Alias dpkg dpkg.exe
Set-Alias du du.exe
Set-Alias echo echo.exe
Set-Alias ed ed.exe
Set-Alias egrep egrep.exe
Set-Alias env env.exe
Set-Alias expand expand.exe
Set-Alias expr expr.exe
Set-Alias factor factor.exe
Set-Alias false false.exe
Set-Alias fgrep fgrep.exe
Set-Alias find D:/custom-command/busybox/find.exe
Set-Alias fold fold.exe
Set-Alias free free.exe
Set-Alias fsync fsync.exe
Set-Alias ftpget ftpget.exe
Set-Alias ftpput ftpput.exe
Set-Alias getopt getopt.exe
Set-Alias grep grep.exe
Set-Alias groups groups.exe
Set-Alias gunzip gunzip.exe
Set-Alias gzip gzip.exe
Set-Alias hd hd.exe
Set-Alias head head.exe
Set-Alias hexdump hexdump.exe
Set-Alias httpd httpd.exe
Set-Alias iconv iconv.exe
Set-Alias id id.exe
Set-Alias inotifyd inotifyd.exe
Set-Alias install install.exe
Set-Alias ipcalc ipcalc.exe
Set-Alias jn jn.exe
Set-Alias kill kill.exe
Set-Alias killall killall.exe
Set-Alias less less.exe
Set-Alias link link.exe
Set-Alias ln ln.exe
Set-Alias logname logname.exe
Set-Alias lsattr lsattr.exe
Set-Alias lzcat lzcat.exe
Set-Alias lzma lzma.exe
Set-Alias lzop lzop.exe
Set-Alias lzopcat lzopcat.exe
Set-Alias make make.exe
Set-Alias man man.exe
Set-Alias md5sum md5sum.exe
Set-Alias mkdir mkdir.exe
Set-Alias mktemp mktemp.exe
Set-Alias mv mv.exe
Set-Alias nc nc.exe
Set-Alias nl nl.exe
Set-Alias nproc nproc.exe
Set-Alias od od.exe
Set-Alias paste paste.exe
Set-Alias patch patch.exe
Set-Alias pgrep pgrep.exe
Set-Alias pidof pidof.exe
Set-Alias pipe_progress pipe_progress.exe
Set-Alias pkill pkill.exe
Set-Alias printenv printenv.exe
Set-Alias printf printf.exe
Set-Alias ps ps.exe
Set-Alias pwd pwd.exe
Set-Alias readlink readlink.exe
Set-Alias realpath realpath.exe
Set-Alias reset reset.exe
Set-Alias rev rev.exe
Set-Alias rm rm.exe
Set-Alias rmdir rmdir.exe
Set-Alias rpm rpm.exe
Set-Alias rpm2cpio rpm2cpio.exe
Set-Alias sed sed.exe
Set-Alias seq seq.exe
Set-Alias sh sh.exe
Set-Alias sha1sum sha1sum.exe
Set-Alias sha256sum sha256sum.exe
Set-Alias sha3sum sha3sum.exe
Set-Alias sha512sum sha512sum.exe
Set-Alias shred shred.exe
Set-Alias shuf shuf.exe
Set-Alias sleep sleep.exe
Set-Alias sort sort.exe
Set-Alias split split.exe
Set-Alias ssl_client ssl_client.exe
Set-Alias stat stat.exe
Set-Alias strings strings.exe
Set-Alias su su.exe
Set-Alias sum sum.exe
Set-Alias sync sync.exe
Set-Alias tac tac.exe
Set-Alias tail tail.exe
Set-Alias tar tar.exe
Set-Alias tee tee.exe
Set-Alias test test.exe
Set-Alias time time.exe
Set-Alias timeout timeout.exe
Set-Alias touch touch.exe
Set-Alias tr tr.exe
Set-Alias true true.exe
Set-Alias truncate truncate.exe
Set-Alias ts ts.exe
Set-Alias tsort tsort.exe
Set-Alias ttysize ttysize.exe
Set-Alias uname uname.exe
Set-Alias uncompress uncompress.exe
Set-Alias unexpand unexpand.exe
Set-Alias uniq uniq.exe
Set-Alias unix2dos unix2dos.exe
Set-Alias unlink unlink.exe
Set-Alias unlzma unlzma.exe
Set-Alias unlzop unlzop.exe
Set-Alias unxz unxz.exe
Set-Alias unzip unzip.exe
Set-Alias uptime uptime.exe
Set-Alias usleep usleep.exe
Set-Alias uudecode uudecode.exe
Set-Alias uuencode uuencode.exe
Set-Alias watch watch.exe
Set-Alias wc wc.exe
Set-Alias wget wget.exe
Set-Alias which which.exe
Set-Alias whoami whoami.exe
Set-Alias whois whois.exe
Set-Alias xargs xargs.exe
Set-Alias xxd xxd.exe
Set-Alias xz xz.exe
Set-Alias xzcat xzcat.exe
Set-Alias yes yes.exe
Set-Alias zcat zcat.exe
Set-Alias sudo gsudo.exe

Set-Alias wails wails.exe

Function cmdcat {
    if ($args.length -gt 0) {
        foreach ($item in $args) {
            Get-Content $item
        }
    } else {
        Get-Content
    }
}
Set-Alias cat cmdcat

Function cmdwls { wsl ~ }
Set-Alias sh cmdwls
Set-Alias bash cmdwls

Function cmdcdc { cd c:/ }
Set-Alias cdc cmdcdc

Function cmdcdd { cd d:/ }
Set-Alias cdd cmdcdd

Function cmdps { cd C:\Users\khpark0203\Documents\PowerShell\Modules }
Set-Alias cdpsmodule cmdps

Function cmdcdholic { cd D:/github/holic/holic-service }
Set-Alias cdholic cmdcdholic

Function cmdcdhost { cd C:/Windows/System32/drivers/etc }
Set-Alias cdhost cmdcdhost
Set-Alias idea idea.cmd

