# catimg.ps1
#
# PowerShell module wrapper around the catimg C binary.
#
# Import from the repository root:
#   Import-Module .\catimg.ps1
#
# After import, the `catimg` function forwards all arguments to
# .\bin\catimg.exe (the Windows MinGW/GCC build). The binary is expected at
# <repo root>\bin\catimg.exe; build it first with .\scripts\build.ps1.
#
# The function accepts pipeline input and forwards it to the binary's stdin,
# so binary image data is passed through byte-exact (unlike `Get-Content`,
# which would mangle PNG/GIF bytes). No `-` sentinel is needed: simply pipe
# the image bytes in and pass any flags as normal arguments.
#
# Examples:
#   catimg -h
#   catimg -r 1 test-images\mewtwo-front.png
#   Get-Content test-images\mewtwo-front.png -Raw | catimg -r 1 -t
#   [IO.File]::ReadAllBytes("test-images\mewtwo-front.png") | catimg -r 1

$CatimgModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:CatimgExe = Join-Path $CatimgModuleRoot "bin\catimg.exe"

function catimg {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Arguments,

        [Parameter(ValueFromPipeline = $true)]
        [object]$PipelineInput
    )

    begin {
        if (-not (Test-Path $script:CatimgExe)) {
            throw "catimg binary not found at '$script:CatimgExe'. Run .\scripts\build.ps1 first."
        }

        $script:stdinBytes = [System.Collections.Generic.List[byte]]::new()
        $script:hasPipelineInput = $false
    }

    process {
        # The process block runs both for real pipeline input and for the
        # no-pipeline case (where the trailing positional argument lands in
        # $PipelineInput). Distinguish the two:
        #  - a string that is an existing image file is a path argument,
        #  - a byte[] (enumerated one byte at a time) or Stream is stdin data,
        #  - everything else is treated as stdin text.
        if ($PipelineInput -is [byte[]]) {
            $script:hasPipelineInput = $true
            $script:stdinBytes.AddRange($PipelineInput)
        } elseif ($PipelineInput -is [System.IO.Stream]) {
            $script:hasPipelineInput = $true
            $PipelineInput.CopyTo($script:stdinBytes)
        } elseif ($PipelineInput -is [byte] -or $PipelineInput -is [int] -or $PipelineInput -is [sbyte] -or $PipelineInput -is [short] -or $PipelineInput -is [long] -or $PipelineInput -is [ushort] -or $PipelineInput -is [uint] -or $PipelineInput -is [ulong]) {
            $script:hasPipelineInput = $true
            $script:stdinBytes.Add([byte]$PipelineInput)
        } elseif ($PipelineInput -is [string]) {
            if (Test-Path -LiteralPath $PipelineInput -PathType Leaf) {
                $Arguments += $PipelineInput
            } else {
                $script:hasPipelineInput = $true
                $script:stdinBytes.AddRange([System.Text.Encoding]::UTF8.GetBytes($PipelineInput))
            }
        } else {
            $script:hasPipelineInput = $true
            $script:stdinBytes.AddRange([System.Text.Encoding]::UTF8.GetBytes([string]$PipelineInput))
        }
        Write-Debug "process: pi=[$PipelineInput] args=[$($Arguments -join ',')] hasInput=$script:hasPipelineInput"
    }

    end {
        if ($script:hasPipelineInput) {
            Write-Debug "end: pipeline branch args=[$($Arguments -join ',')] stdinBytes=$($script:stdinBytes.Count)"
            # Pipeline data present: write it to a temporary file and run the
            # binary with stdin redirected from that file. The child's stdout is
            # also redirected to a temp file and then written to this function's
            # stdout as raw bytes, so the caller's `>` redirection and ANSI
            # rendering both work.
            $tmpInFile = [System.IO.Path]::GetTempFileName()
            $tmpOutFile = [System.IO.Path]::GetTempFileName()
            try {
                [System.IO.File]::WriteAllBytes($tmpInFile, $script:stdinBytes.ToArray())

                # catimg treats its last argument as the image path, so pass the
                # temp file as the trailing argument (replacing any `-` sentinel
                # the caller may have included).
                $argsList = [System.Collections.Generic.List[object]]::new($Arguments)
                while ($argsList.Count -gt 0 -and [string]$argsList[$argsList.Count - 1] -eq '-') {
                    $argsList.RemoveAt($argsList.Count - 1)
                }
                $argsList.Add($tmpInFile)

                $argStr = ""
                foreach ($a in $argsList) {
                    $s = [string]$a
                    if ($s -eq "") { $argStr += ' ""' }
                    elseif ($s -match '\s') { $argStr += ' "' + ($s -replace '"', '""') + '"' }
                    else { $argStr += " $s" }
                }
                $argStr = $argStr.Trim()

                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = $script:CatimgExe
                $psi.Arguments = $argStr
                $psi.RedirectStandardOutput = $true
                $psi.UseShellExecute = $false

                $proc = [System.Diagnostics.Process]::Start($psi)
                $ms = New-Object System.IO.MemoryStream
                $proc.StandardOutput.BaseStream.CopyTo($ms)
                $proc.WaitForExit()
                if ($proc.ExitCode -ne 0) { $script:ExitCode = $proc.ExitCode }

                [System.IO.File]::WriteAllBytes($tmpOutFile, $ms.ToArray())
            } finally {
                if (Test-Path -LiteralPath $tmpInFile) {
                    Remove-Item -LiteralPath $tmpInFile -ErrorAction SilentlyContinue
                }
            }

            # Write the captured output to this function's stdout as raw bytes.
            # Write-Output (not $PSCmdlet.Write) is required: the latter
            # discards byte[] output when the caller redirects stdout.
            $outBytes = [System.IO.File]::ReadAllBytes($tmpOutFile)
            Write-Output $outBytes -NoEnumerate
            Remove-Item -LiteralPath $tmpOutFile -ErrorAction SilentlyContinue
        } else {
            Write-Debug "end: no-pipeline branch args=[$($Arguments -join ',')]"
            # No pipeline input: run the binary normally (stdin stays attached).
            & $script:CatimgExe @Arguments
            if ($LASTEXITCODE -ne 0) { $script:ExitCode = $LASTEXITCODE }
        }
    }
}

# (No Export-ModuleMember: top-level functions are exported automatically when
# the script is imported as a module, and Export-ModuleMember errors when the
# script is dot-sourced instead.)