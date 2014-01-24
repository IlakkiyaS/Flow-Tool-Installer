; This script builds the windows executable for Flow Tool
; 12 27 2013: Ilakkiya S
; Flow Tool Project

; ---------------------------------------------------------------------------------------------------------------------------------------------
; Start

!include "${NSISDIR}\Contrib\Modern UI\System.nsh"
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "winmessages.nsh"
!include "FileFunc.nsh"
!include "nsDialogs.nsh"

SetCompressor lzma

;----------------------------------------------------------------------------------------------------------------------------------------------
;General

!define PRODUCT_NAME "Flow Tool 1.0"
!define FLOW_FILE Spoon.bat
; Modify this directory to point to your local Flow Tool installation
!define TO_COPY_DIR "C:\Users\311771\Desktop\NSIS installer\pdi-ce-4.2.0-stable\data-integration-limited"

Name "${PRODUCT_NAME}"
OutFile "..\${PRODUCT_NAME}.exe"
InstallDir "$PROGRAMFILES\hpcc-systems\flow"
InstallDirRegKey  HKLM "Software\Microsoft\Windows\CurrentVersion\App Paths\${PRODUCT_NAME}.exe" ""
ShowInstDetails "nevershow"
ShowUninstDetails "nevershow"
RequestExecutionLevel admin

;------------------------------------------------------------------------------------------------------------------------------------------------
;Modern UI Configuration

!define MUI_ABORTWARNING_TEXT "Are you sure you wish to abort installation?"
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\classic-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\classic-uninstall.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "logo_installer.bmp"
!define WControlPanelItem_Add

;------------------------------------------------------------------------------------------------------------------------------------------------
;Installer Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
Page Custom pre nsDialogsPageLeave
!define MUI_FINISHPAGE_RUN "$INSTDIR\${FLOW_FILE}"
!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Create Desktop Shortcut"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION finishpageaction
!insertmacro MUI_PAGE_FINISH

!macro WControlPanelItem_Add `GUID` `Name` `Tip` `Exec` `Icon`
  WriteRegStr HKCR `CLSID\${GUID}` `` `${Name}`
  WriteRegStr HKCR `CLSID\${GUID}` `InfoTip` `${Tip}`
  WriteRegStr HKCR `CLSID\${GUID}\DefaultIcon` `` `${Icon}`
  WriteRegStr HKCR `CLSID\${GUID}\Shell\Open\Command` `` `${Exec}`
  WriteRegDWORD HKCR `CLSID\${GUID}\ShellFolder` `Attributes` `0`
  WriteRegStr HKLM `SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\${GUID}` `` `${Name}`
!macroend
 !insertmacro GetTime
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

;-------------------------------------------------------------------------------------------------------------------------------------------------
;Language

 !insertmacro MUI_LANGUAGE "English"

;--------------------------------------------------------------------------------------------------------------------------------------------------
var Label
var Label1
var Label2
var Label3
var Label4
var Label5
var Label6
var Label7
var Label8
var Label9

var dialog
var Text
var Text1
var Text2
var Text3
var Text4
var Text5
var Text6
var Text7
var Text8
var Text9

Var InstallPage.DirRequest
Var InstallPage1.DirRequest
Var InstallPage2.DirRequest
Var InstallPage3.DirRequest
Var InstallPage.BrowseButton



; --------------------------------------------------------------------------------------------------------------------------------------------------
;Installer Sections

; Section 1 -  Checks for Administrator privileges
Section

    # call UserInfo plugin to get user info.  The plugin puts the result in the stack
    UserInfo::getAccountType

    # pop the result from the stack into $0
    Pop $0

    # compare the result with the string "Admin" to see if the user is admin.
    # If match, jump 3 lines down.
    StrCmp $0 "Admin" +3

    # if there is not a match, print message and return
    MessageBox MB_OK "This installer requires Administrator privileges to run."
    quit

    # otherwise, confirm and return
    MessageBox MB_OK "The User is Admin"
SectionEnd

; Section 2 -  Performs JAVA Installation Check - Verified in the system registry.
section "Java Check"
     # read the value from the registry into the $0 register
     readRegStr $0 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment" CurrentVersion

     StrCmp $0 "" jre_not_found jre_found

       jre_not_found:
       ;jdk check
      ReadRegStr $0 HKLM "SOFTWARE\JavaSoft\Java Development Kit" CurrentVersion
       StrCmp $0 "" java_not_found jre_found

      java_not_found:
       # message saying java need to install
      MessageBox MB_YESNOCANCEL "Java is required.  Would you like to download it now? (Please restart this installer after installing .Java)" IDNO +2 IDCANCEL +2
      ExecShell open "http://www.oracle.com/technetwork/java/javase/downloads/index.html"
      Abort

      jre_found:
      # checking java version
       Push "1.6" ;Needed verion of product
       Push  $0   ;Here you have to put existing version of product on target computer
       Call CompareVersions
       Pop $0   ; If $R0 = '1' then existing version greater than or  equval to a needed version
           ${If} $0 == "1"
                MessageBox MB_OK "Java Exists"
           ${Else}
                 # message saying new version of java needed to be installed
                   MessageBox MB_YESNOCANCEL "Higher version of java(1.6.0.17 or higher) is required.  Would you like to download it now?" IDNO +2 IDCANCEL +2
                   ExecShell open "http://www.oracle.com/technetwork/java/javase/downloads/index.html"
                   Abort
           ${EndIf}

sectionEnd

; Section 3 -  Performs HPCC Client Tools Installation Check - Verified in the system registry. @TODO Change based on Joe's inputs.
section "HPCC Check"

       # read the value from the registry into the $1 register
        readRegStr $1 HKLM "SOFTWARE\HPCC Systems\clienttools_4.2.0" ""
        StrCmp $1 "" hpcc_not_found hpcc_found

        hpcc_not_found:
        # message saying java need to install
        MessageBox MB_YESNOCANCEL "HPCC is required.  Would you like to download it now? (Please restart this installer after installing it)" IDNO +2 IDCANCEL +2
        ExecShell open "http://hpccsystems.com/download/free-community-edition/client-tools"
        Abort

        hpcc_found:
        MessageBox MB_OK "HPCC tool version : $1"

sectionEnd

; Section 4
; Copies the Flow tool to the installation directory
; Writes Uninstaller
; Creates Start menu items, Registry Key(For verifying if the tool already exists) and program entry in Control Panel.

Section

SetOutPath "$INSTDIR"
File /r /x "${TO_COPY_DIR}\FlowTool.nsi" "${TO_COPY_DIR}\*.*"

WriteUninstaller "$INSTDIR\Uninstall.exe"

;CREATE Start menu items

CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" "$INSTDIR\${FLOW_FILE}"
CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

;CREATE REGISTRY KEYS FOR ADD/REMOVE PROGRAMS IN CONTROL PANEL

WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayName"\
"Flow Tool"
WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString" \
"$INSTDIR\Uninstall.exe"

SectionEnd

Function pre
	!insertmacro MUI_HEADER_TEXT "HPCC Default config:" "Fill The Below Details"
         nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

;	nsDialogs::CreateControl STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS} 10 0 10% 20%  100 "Default_cluster"
        ${NSD_CreateLabel} 5u 15u 90u 15u "Default Cluster"
        POP $Label
	${NSD_CreateText} 120u 15u 140u 10u  ""
        Pop $Text

        ;nsDialogs::CreateControl STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS} 10 0 10% 20%  10  "Default_port"
        ${NSD_CreateLabel} 5u 27u 90u 15u "Default Port"
        POP $Label1
       ${NSD_CreateNumber} 120u 27u 140u 10u ""
	Pop $Text1

        ;nsDialogs::CreateControl STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS} 0 60 10% 20%  "Default_host"
        ${NSD_CreateLabel} 5u 39u 90u 15u "Default Host"
        POP $Label2
 	${NSD_CreateText} 120u 39u 140u 10u ""
	Pop $Text2

        ;nsDialogs::CreateControl STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS} 0 90 10% 20%    "Default_Landing_Zone"
         ${NSD_CreateLabel} 5u 51u 90u 15u "Default Landing Zone"
         POP $Label3
	${NSD_CreateText} 120u 51u 140u 10u ""
	Pop $Text3

        ${NSD_CreateLabel} 5u 63u 90u 15u "Default Return Rows Limit"
        POP $Label4
	${NSD_CreateText} 120u 63u 140u 10u ""
	Pop $Text4

	${NSD_CreateLabel} 5u 75u 90u 15u "Default ECL Location"
	POP $Label5
	 readRegStr $1 HKLM "SOFTWARE\HPCC Systems\clienttools_4.2.0" ""
	${NSD_CreateText} 120u 75u 140u 10u "$1\bin"
	Pop $Text5

	${NSD_CreateLabel} 5u 87u 90u 15u "Default MLL Location"
	POP $Label6
	${NSD_CreateDirRequest} 120u 87u 140u 10u  "$INSTDIR"
        Pop $InstallPage.DirRequest
        ${NSD_OnChange} $InstallPage.DirRequest DirRequestOnChange
        ${NSD_CreateBrowseButton} 270u 87u 15u 10u "..."
        Pop $InstallPage.BrowseButton
        ${NSD_OnClick} $InstallPage.BrowseButton OnClick_BrowseButton
        Pop $Text6


	${NSD_CreateLabel} 5u 99u 100u 15u "Default SALt Library Location"
	POP $Label7
	${NSD_CreateDirRequest} 120u 99u 140u 10u "$INSTDIR"
        Pop $InstallPage1.DirRequest
        ${NSD_OnChange} $InstallPage1.DirRequest DirRequestOnChange1
        ${NSD_CreateBrowseButton} 270u 99u 15u 10u "..."
        Pop $InstallPage.BrowseButton
        ${NSD_OnClick} $InstallPage.BrowseButton OnClick_BrowseButton1
        Pop $Text7

	${NSD_CreateLabel} 5u 111u 110u 15u "Default SALt Executable Location"
	POP $Label8
	${NSD_CreateDirRequest} 120u 111u 140u 10u "$INSTDIR"
	Pop $InstallPage2.DirRequest
        ${NSD_OnChange} $InstallPage2.DirRequest DirRequestOnChange2
        ${NSD_CreateBrowseButton} 270u 111u 15u 10u "..."
        Pop $InstallPage.BrowseButton
        ${NSD_OnClick} $InstallPage.BrowseButton OnClick_BrowseButton2
	Pop $Text8

	${NSD_CreateLabel} 5u 123u 90u 15u "Default SALt Include"
	POP $Label9
	${NSD_CreateDirRequest} 120u 123u 140u 10u "$INSTDIR"
	Pop $InstallPage3.DirRequest
        ${NSD_OnChange} $InstallPage2.DirRequest DirRequestOnChange3
        ${NSD_CreateBrowseButton} 270u 123u 15u 10u "..."
        Pop $InstallPage.BrowseButton
        ${NSD_OnClick} $InstallPage.BrowseButton OnClick_BrowseButton3
	Pop $Text9
	nsDialogs::Show

FunctionEnd

Function nsDialogsPageLeave
	${NSD_GetText} $Text  $0
	${NSD_GetText} $Text1 $1
	${NSD_GetText} $Text2 $2
	${NSD_GetText} $Text3 $3
	${NSD_GetText} $Text4 $4
	${NSD_GetText} $Text5 $5
	${NSD_GetText} $InstallPage.DirRequest $6
	${NSD_GetText} $InstallPage1.DirRequest $7
	${NSD_GetText} $InstallPage2.DirRequest $8
        ${NSD_GetText} $InstallPage3.DirRequest $9
     SetOutPath "$INSTDIR"
     FileOpen $R1 $INSTDIR\hpcc_systems.PROPERTIES w
FileSeek $R1 0 END
${GetTime} "" "L" $R0 $R7 $R2 $R3 $R4 $R5 $R6
FileWrite $R1   'Date=$R0/$R7/$R2 ($3)$\nTime=$R4:$R5:$R6'

FileWrite $R1  "$\r$\nhpcc.cluster=$0"

FileWrite $R1 "$\r$\nhpcc.port=$1"

FileWrite $R1 "$\r$\nhpcc.host=$2"

FileWrite $R1 "$\r$\nhpcc.landingzone=$3"

FileWrite $R1 "$\r$\nhpcc.maxreturn=$4"

FileWrite $R1 "$\r$\nhpcc.eclcc=$5"

FileWrite $R1 "$\r$\nml.lib=$6"

FileWrite $R1 "$\r$\nsalt.lib=$7"

FileWrite $R1 "$\r$\nsalt.exe=$8"

FileWrite $R1 "$\r$\nsalt.include=$9"

FileClose $R1
FunctionEnd

; --------------------------------------------------------------------------------------------------------------------------------------------------
;  Functions to be called on initialization
;  1. Verifying if the tool already exists
;  2. Presenting the Splash screen
Function .onInit
readRegStr $1 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"  UninstallString
StrCmp $1 "" tool_not_found tool_found

        tool_found:
                MessageBox MB_OK "Flow tool installation already exists"
                Quit
         tool_not_found:
                  # the plugins dir is automatically deleted when the installer exits
         	InitPluginsDir
           	File /oname=$PLUGINSDIR\splash.bmp "${TO_COPY_DIR}\Flow.bmp"
          	#optional
        	#File /oname=$PLUGINSDIR\splash.wav "C:\myprog\sound.wav"

         	splash::show 1000 $PLUGINSDIR\splash

        	Pop $0 ; $0 has '1' if the user closed the splash screen early,
			; '0' if everything closed normally, and '-1' if some error occurred.


FunctionEnd

; --------------------------------------------------------------------------------------------------------------------------------------------------
;Checks Java Version 1.6 or higher

Function CompareVersions
   ; stack: existing ver | needed ver
   Exch $R0
   Exch
   Exch $R1
   ; stack: $R1|$R0

   Push $R1
   Push $R0
   ; stack: e|n|$R1|$R0

   ClearErrors
   loop:
      IfErrors VersionNotFound
      Strcmp $R0 "" VersionTestEnd

      Call ParseVersion
      Pop $R0
      Exch

      Call ParseVersion
      Pop $R1
      Exch

      IntCmp $R1 $R0 +1 VersionOk VersionNotFound
      Pop $R0
      Push $R0

   goto loop

   VersionTestEnd:
      Pop $R0
      Pop $R1
      Push $R1
      Push $R0
      StrCmp $R0 $R1 VersionOk VersionNotFound

   VersionNotFound:
      StrCpy $R0 "0"
      Goto end

   VersionOk:
      StrCpy $R0 "1"
end:
   ; stack: e|n|$R1|$R0
   Exch $R0
   Pop $R0
   Exch $R0
   ; stack: res|$R1|$R0
   Exch
   ; stack: $R1|res|$R0
   Pop $R1
   ; stack: res|$R0
   Exch
   Pop $R0
   ; stack: res
FunctionEnd

;--------------------------------config part function--------------------------------------------
Function DirRequestOnChange
   Pop $0
   System::Call `user32::GetWindowText(i$InstallPage.DirRequest, t.r0, i${NSIS_MAX_STRLEN})`
   StrCpy $INSTDIR $0
FunctionEnd

Function DirRequestOnChange1
   Pop $0
   System::Call `user32::GetWindowText(i$InstallPage1.DirRequest, t.r0, i${NSIS_MAX_STRLEN})`
   StrCpy $INSTDIR $0
FunctionEnd
Function DirRequestOnChange2
   Pop $0
   System::Call `user32::GetWindowText(i$InstallPage2.DirRequest, t.r0, i${NSIS_MAX_STRLEN})`
   StrCpy $INSTDIR $0
FunctionEnd
Function DirRequestOnChange3
   Pop $0
   System::Call `user32::GetWindowText(i$InstallPage3.DirRequest, t.r0, i${NSIS_MAX_STRLEN})`
   StrCpy $INSTDIR $0
FunctionEnd


Function OnClick_BrowseButton1
  Pop $0

  Push $INSTDIR ; input string "C:\Program Files\ProgramName"
  Call GetParent
  Pop $R0 ; first part "C:\Program Files"

  Push $INSTDIR ; input string "C:\Program Files\ProgramName"
  Push "\" ; input chop char
  Call GetLastPart
  Pop $R1 ; last part "ProgramName"

  nsDialogs::SelectFolderDialog /NOUNLOAD \
    "Select the folder to install $R0 in." $R0
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
    StrCpy $INSTDIR "$0\$R1"
    system::Call `user32::SetWindowText(i $InstallPage1.DirRequest, t "$INSTDIR")`
  ${EndIf}
FunctionEnd
Function OnClick_BrowseButton2
  Pop $0

  Push $INSTDIR ; input string "C:\Program Files\ProgramName"
  Call GetParent
  Pop $R0 ; first part "C:\Program Files"

  Push $INSTDIR ; input string "C:\Program Files\ProgramName"
  Push "\" ; input chop char
  Call GetLastPart
  Pop $R1 ; last part "ProgramName"

  nsDialogs::SelectFolderDialog /NOUNLOAD \
    "Select the folder to install $R0 in." $R0
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
    StrCpy $INSTDIR "$0\$R1"
    system::Call `user32::SetWindowText(i $InstallPage2.DirRequest, t "$INSTDIR")`
  ${EndIf}
FunctionEnd
Function OnClick_BrowseButton
  Pop $0

  Push $INSTDIR ; input string "C:\Program Files\ProgramName"
  Call GetParent
  Pop $R0 ; first part "C:\Program Files"

  Push $INSTDIR ; input string "C:\Program Files\ProgramName"
  Push "\" ; input chop char
  Call GetLastPart
  Pop $R1 ; last part "ProgramName"

  nsDialogs::SelectFolderDialog /NOUNLOAD \
    "Select the folder to install $R0 in." $R0
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
    StrCpy $INSTDIR "$0\$R1"
    system::Call `user32::SetWindowText(i $InstallPage.DirRequest, t "$INSTDIR")`
  ${EndIf}
FunctionEnd
Function OnClick_BrowseButton3
  Pop $0

  Push $INSTDIR ; input string "C:\Program Files\ProgramName"
  Call GetParent
  Pop $R0 ; first part "C:\Program Files"

  Push $INSTDIR ; input string "C:\Program Files\ProgramName"
  Push "\" ; input chop char
  Call GetLastPart
  Pop $R1 ; last part "ProgramName"

  nsDialogs::SelectFolderDialog /NOUNLOAD \
    "Select the folder to install $R0 in." $R0
  Pop $0
  ${If} $0 == "error" # returns 'error' if 'cancel' was pressed?
    Return
  ${EndIf}
  ${If} $0 != ""
    StrCpy $INSTDIR "$0\$R1"
    system::Call `user32::SetWindowText(i $InstallPage3.DirRequest, t "$INSTDIR")`
  ${EndIf}
FunctionEnd
Function GetParent
  Exch $R0 ; input string
  Push $R1
  Push $R2
  Push $R3
  StrCpy $R1 0
  StrLen $R2 $R0
  loop:
    IntOp $R1 $R1 + 1
    IntCmp $R1 $R2 get 0 get
    StrCpy $R3 $R0 1 -$R1
    StrCmp $R3 "\" get
    Goto loop
  get:
    StrCpy $R0 $R0 -$R1
    Pop $R3
    Pop $R2
    Pop $R1
    Exch $R0 ; output string
FunctionEnd

; Usage:
; Push $INSTDIR ; input string "C:\Program Files\ProgramName"
; Push "\" ; input chop char
; Call GetLastPart
; Pop $R1 ; last part "ProgramName"
Function GetLastPart
  Exch $0 ; chop char
  Exch
  Exch $1 ; input string
  Push $2
  Push $3
  StrCpy $2 0
  loop:
    IntOp $2 $2 - 1
    StrCpy $3 $1 1 $2
    StrCmp $3 "" 0 +3
      StrCpy $0 ""
      Goto exit2
    StrCmp $3 $0 exit1
    Goto loop
  exit1:
    IntOp $2 $2 + 1
    StrCpy $0 $1 "" $2
  exit2:
    Pop $3
    Pop $2
    Pop $1
    Exch $0 ; output string
FunctionEnd

;--------------------------------congig end-------------------------------

;---------------------------------------------------------------------------------------
 ; ParseVersion
 ; input:
 ;      top of stack = version string ("xx.xx.xx.xx")
 ; output:
 ;      top of stack   = first number in version ("xx")
 ;      top of stack-1 = rest of the version string ("xx.xx.xx")
Function ParseVersion
   Exch $R1 ; version
   Push $R2
   Push $R3

   StrCpy $R2 1
   loop:
      StrCpy $R3 $R1 1 $R2
      StrCmp $R3 "." loopend
      StrLen $R3 $R1
      IntCmp $R3 $R2 loopend loopend
      IntOp $R2 $R2 + 1
      Goto loop
   loopend:
   Push $R1
   StrCpy $R1 $R1 $R2
   Exch $R1

   StrLen $R3 $R1
   IntOp $R3 $R3 - $R2
   IntOp $R2 $R2 + 1
   StrCpy $R1 $R1 $R3 $R2

   Push $R1

   Exch 2
   Pop $R3

   Exch 2
   Pop $R2

   Exch 2
   Pop $R1
FunctionEnd

; --------------------------------------------------------------------------------------------------------------------------------------------------
; Function to create desktop shortcut

Function finishpageaction
CreateShortcut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${FLOW_FILE}" "" "$INSTDIR\icon_new.ico"
FunctionEnd

; --------------------------------------------------------------------------------------------------------------------------------------------------
; Uninstaller Section

Section "Uninstall"

;Delete Start Menu Shortcuts
Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
Delete "$SMPROGRAMS\${PRODUCT_NAME}\*.*"
RmDir  "$SMPROGRAMS\${PRODUCT_NAME}"

;Delete Files
RMDir /r "$INSTDIR"

;Remove the installation directory
RMDir "$INSTDIR"

;Remove registry entry
DeleteRegKey /ifempty  HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"

SectionEnd

; --------------------------------------------------------------------------------------------------------------------------------------------------

;eof
