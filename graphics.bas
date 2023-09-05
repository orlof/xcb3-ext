{
    // See https://go.microsoft.com/fwlink/?LinkId=733558
    // for the documentation about the tasks.json format
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build XC_BASIC file to .prg",
            "type": "shell",
            "osx": {
                "command": "./bin/macOS/xcbasic3",
                "args": [
                    "-p=False",
                    "-k",
                    "${file}",
                    "${fileDirname}/${fileBasenameNoExtension}.prg"
                ]
            },
            "linux": {
                "command": "./bin/Linux/xcbasic3",
                "args": [
                    "${file}",
                    "${fileDirname}/${fileBasenameNoExtension}.prg"
                ]
            },
            "windows": {
                "command": "./bin/Windows/xcbasic3.exe",
                "args": [
                    "${file}",
                    "${fileDirname}\\${fileBasenameNoExtension}.prg"
                ]
            },
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "options": {
                "cwd": "${config:xcbasic.basefolder}"
            }
        }
    ]
}
