# PowerShell argument completer for the `catimg` function defined in catimg.ps1.
#
# Install once:
#   . .\completion\_catimg.ps1
#
# To load it automatically for every PowerShell session, add that line to your
# $PROFILE (see "Installation" in README.md).

# Options as (completionText, helpText) pairs. A hash table is avoided so the
# case-sensitive keys -h and -H can coexist.
$script:catimgOptions = @(
    @('-h', 'display a help message'),
    @('-H', 'specify the height of the displayed image'),
    @('-w', 'specify the width of the displayed image'),
    @('-l', 'specify the amount of loops that catimg should repeat a GIF'),
    @('-r', 'force the resolution of the image'),
    @('-c', 'convert colors to a restricted palette'),
    @('-t', 'disable true color and use 256 color instead')
)

Register-ArgumentCompleter -CommandName catimg -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $parameters)

    # -r takes a numeric resolution argument; complete nothing for it.
    if ($parameters -and $parameters['-r'] -ne $null) { return }

    foreach ($pair in $script:catimgOptions) {
        $opt = $pair[0]
        if ($opt -like "$wordToComplete*") {
            [System.Management.Automation.CompletionResult]::new(
                $opt,
                $opt,
                'Parameter',
                $pair[1]
            )
        }
    }

    # File completion for the image path argument.
    if (-not $parameters) {
        $path = $wordToComplete
        if ([string]::IsNullOrEmpty($path)) { $path = '.' }
        Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -match '\.(png|jpg|jpeg|gif|bmp|tga|psd|hdr|pic|ico)$' } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    $_.Name,
                    $_.Name,
                    'File',
                    $_.Name
                )
            }
    }
}