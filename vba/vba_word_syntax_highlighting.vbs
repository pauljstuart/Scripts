'
'
'  A Microsoft Word VBA macro to do syntax highlighting
'
'  How does it work?
'
'  Basically, you add the following VBA code to your normal.dotm.
'  It's then a fairly straightforward matter to execute the macro called ToCode()
'  either by running it directly, or by associating that sub with a button on the
'  ribbon.
'
'  Note : the document you doing the syntax highlighting in needs a 'Code' style.
'  The attributes of this style are up to you.
'
' - Paul Stuart



' Format the selected text so it looks sort of like code.
' Note: First define the Code style.
Public Sub ToCode()
Dim selection_range As Range

Dim s As style

bExists = False
For Each s In ActiveDocument.Styles
  If s.NameLocal = "Code" Then
    bExists = True
  End If
Next s

If bExists = False Then
  MsgBox ("Code style does not exist in this document")
  End
End If

    ' Get the selected range.
    Set selection_range = Selection.Range

    ' Set the code styles, straighten quotes, and color
    ' comments.
    SetCodeStyles selection_range
    StraightenQuotes selection_range
   

   Call AssociateStyle("(^|\s)ALL[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)ALTER[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)AND[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)ANY[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)ARRAY[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)ARROW[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)AS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)ASC[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)AT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)*BEGIN[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)BETWEEN[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)BY[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)CASE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)CHECK[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)CLUSTERS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)CLUSTER[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)COLAUTH[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)COLUMNS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)COLUMN[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)COMPRESS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)CONNECT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)CRASH[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)CREATE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)CURRENT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)CURSOR[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)COMMIT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)DECIMAL[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)DECLARE", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)DEFAULT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)\sDELETE\s[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)DESC[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)DISTINCT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)DROP[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)ELSE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)END[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)EXCEPTION[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)EXCLUSIVE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)EXEC[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)EXISTS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)FETCH[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)FORM[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)FORMAT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)FOR[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)FROM[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)GRANT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)GROUP[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)HAVING[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)IDENTIFIED[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)IF[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)IN[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)INDEXES[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)INDEX[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)INSERT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)INTERSECT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)INTO[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)IS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)LIKE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)LOCK[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)LOOP[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)MINUS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)MODE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)NOCOMPRESS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)NOT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)NOWAIT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)NULL[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)OF[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)OPEN[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)ON[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)OPTION[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)OR[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)ORDER[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)OVERLAPS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)PRIOR[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)PROCEDURE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)PUBLIC[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)RANGE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)RECORD[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)RESOURCE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)REVOKE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)SELECT[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)SHARE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)SIZE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)SQL[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)SET[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)START[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)SUBTYPE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)TABAUTH[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)TABLE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)THEN[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)TO[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)TYPE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)UNION[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)UNIQUE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)UPDATE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)USE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)VALUES[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)VIEW[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)VIEWS[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)WHEN[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)WHERE[\s;]", "Code", wdBlue, selection_range)
   Call AssociateStyle("(^|\s)WITH[\s;]", "Code", wdBlue, selection_range)
   
   ColorComments selection_range
End Sub



' Set the range's last paragraph's style to Code Last.
' Set the other paragraphs' styles to Code.
Public Sub SetCodeStyles(ByVal rng As Range)
    Set selection_range = Selection.Range
'    If selection_range.Paragraphs.Count = 1 Then
'        selection_range.style = ActiveDocument.Styles("Code " & "Single")
'    Else
        selection_range.style = ActiveDocument.Styles("Code")
 '       selection_range.Paragraphs(1).Style = _
  '          ActiveDocument.Styles("Code First")
   '     selection_range.Paragraphs(selection_range.Paragraphs.Count).Style _
    '        = ActiveDocument.Styles("Code Last")
 '   End If
End Sub



'
'  Color any comments - and literals inside quotes - as green
'
Public Sub ColorComments(ByVal rng As Range)
Dim para As Paragraph
Dim para2 As Paragraph
Dim txt As String
Dim start_point As Integer
Dim end_point As Integer
Dim comment_open As Boolean
Dim comment_range As Range


' Look for comments.
For Each para In rng.Paragraphs
        txt = para.Range.Text
        start_point = InStr(txt, "--")
        If start_point > 0 Then
            Set comment_range = ActiveDocument.Range(para.Range.Start + start_point - 1, para.Range.Start + Len(txt))
            comment_range.Font.Color = wdColorGreen
            comment_range.Case = wdLowerCase
        End If
Next para

' look for  /*.....*/ comments
comment_open = False

For Each para In rng.Paragraphs
        txt = para.Range.Text
        
        start_point = 0
        start_point = InStr(txt, "/*")
        If start_point > 0 Then
            Set comment_range = ActiveDocument.Range(para.Range.Start + start_point, para.Range.End)
            comment_range.Font.Color = wdColorGreen
            comment_open = True
        End If
        
        start_point = InStr(txt, "*/")
        If start_point > 0 Then
              Set comment_range = ActiveDocument.Range(para.Range.Start, para.Range.Start + start_point + 2)
              comment_range.Font.Color = wdColorGreen
              comment_open = False
        End If
        
        If comment_open = True And InStr(txt, "*/") = 0 And InStr(txt, "/*") = 0 Then
              para.Range.Font.Color = wdColorGreen
        End If
     
       
Next para

' look for strings contained inside single quotes
comment_open = False

For Each para In rng.Paragraphs
        txt = para.Range.Text
        
        start_point = 0
        end_point = 0
        end_point = InStr(txt, "*/")
        start_point = InStr(txt, "/*")
        
        If start_point > 0 And end_point = 0 Then
            Set comment_range = ActiveDocument.Range(para.Range.Start + start_point, para.Range.End)
            comment_range.Font.Color = wdColorGreen
            comment_open = True
        End If
        
        
        If end_point > 0 And start_point = 0 Then
              Set comment_range = ActiveDocument.Range(para.Range.Start, para.Range.Start + end_point + 2)
              comment_range.Font.Color = wdColorGreen
              comment_open = False
        End If
        

        If end_point > 0 And start_point > 0 Then
              Set comment_range = ActiveDocument.Range(para.Range.Start + start_point, para.Range.Start + end_point)
              comment_range.Font.Color = wdColorGreen
              comment_open = False
        End If
        
        If comment_open = True And start_point = 0 And end_point = 0 Then
              para.Range.Font.Color = wdColorGreen
        End If
     
       
Next para


End Sub



' Replace curly quotes with straight quotes.
Public Sub StraightenQuotes(ByVal rng As Range)
Dim old_replace_quotes As Boolean

    old_replace_quotes = _
        Options.AutoFormatAsYouTypeReplaceQuotes
    Options.AutoFormatAsYouTypeReplaceQuotes = False

    rng.Find.ClearFormatting
    rng.Find.Replacement.ClearFormatting
    With rng.Find
        .Forward = True
        .Wrap = wdFindStop
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False

        .Text = "'"
        .Replacement.Text = "'"
        .Execute Replace:=wdReplaceAll

        .Text = """"
        .Replacement.Text = """"
        .Execute Replace:=wdReplaceAll
    End With

    Options.AutoFormatAsYouTypeReplaceQuotes = _
        old_replace_quotes
End Sub

Sub AssociateStyle(pattern As String, style As String, colour As Long, ByVal rng As Range)
'Associate Styles with headings and quotations
'Ensure Tools?References?Microsoft VBscript Regular Expression 5.5 is on

Dim regEx, Match
'Dim Matches As MatchCollection
Dim str As String
Dim region As Range

Set regEx = CreateObject("VBScript.RegExp")
regEx.pattern = pattern           ' Set pattern.
regEx.Global = True
regEx.MultiLine = True
regEx.IgnoreCase = True

'obtain matched RegExp.
Set Matches = regEx.Execute(rng.Text)
'MsgBox (Matches.Count)
'loop through and replace style
For Each Match In Matches
     'MsgBox (Match.FirstIndex)
     'MsgBox (Len(Match.Value))
    Set region = ActiveDocument.Range(rng.Start + Match.FirstIndex, rng.Start + Match.FirstIndex + Len(Match.Value))
    If colour > -1 Then
   '     MsgBox (Match.Value)
    '    MsgBox (Match.FirstIndex)
     '   MsgBox (Len(Match.Value))
        region.Font.ColorIndex = colour
        region.Case = wdUpperCase
    Else
        region.style = ActiveDocument.Styles(style)
    End If
Next

End Sub


