Sub MoveReadItems()
 
    Dim objOutlook As Outlook.Application
    Dim objNamespace As Outlook.NameSpace
    Dim objSourceFolder As Outlook.MAPIFolder
    Dim objDestFolder As Outlook.MAPIFolder
    Dim obj As Variant
    Dim sDate As Date
    Dim sAge As Integer
    Dim lngMovedItems As Long
    Dim intDateDiff As Integer
    Dim intCount As Integer

    
    Set objOutlook = Application
    Set objNamespace = objOutlook.GetNamespace("MAPI")
    Set objSourceFolder = objNamespace.GetDefaultFolder(olFolderInbox)
    'Set objDestFolder = objSourceFolder.Folders("Keep2018")

  Set objDestFolder = objNamespace.Folders("paul.stuart@ubs.com").Folders("Keep2018")

    Set colItems = objSourceFolder.Items
    Set colfiltereditems = colItems.Restrict("[UnRead] = False")

For intMessage = colfiltereditems.Count To 1 Step -1
    colfiltereditems(intMessage).Move objDestFolder
         lngMovedItems = lngMovedItems + 1
Next

    ' Display the number of items that were moved.
    MsgBox "Moved " & lngMovedItems & " messages(s)."
Set objDestFolder = Nothing

End Sub
