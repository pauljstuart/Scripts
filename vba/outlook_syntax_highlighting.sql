Public Sub FormatSelectedText()

    Dim myInspector As Outlook.Inspector
    Dim myObject As Object
    Dim myItem As Outlook.MailItem
    Dim myDoc As Word.Document
    Dim mySelection As Word.Selection
    Dim strItem As String
    Dim strGreeting As String
     Dim selection_range As Range

    Set myInspector = Application.ActiveInspector
    Set myObject = myInspector.CurrentItem

    'The active inspector is displaying a mail item.
 

    If myInspector.IsWordMail = True Then
 
        Set myItem = myInspector.CurrentItem
 
        'Grab the body of the message using a Word Document object.
        Set myDoc = myInspector.WordEditor
        'myDoc.Range.Find.ClearFormatting
 
        Set mySelection = myDoc.Application.Selection
 
        mySelection.Font.Color = wdColorBlack
        mySelection.Font.Size = 9
        mySelection.Font.Name = "Lucida Console"
        
        ' Get the selected range.
        Set selection_range = mySelection.Range
    
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
        Call AssociateStyle("(^|\s)PARALLEL[\s;]", "Code", wdBlue, selection_range)
        Call AssociateStyle("(^|\s)PUBLIC[\s;]", "Code", wdBlue, selection_range)
        Call AssociateStyle("(^|\s)RANGE[\s;]", "Code", wdBlue, selection_range)
        Call AssociateStyle("(^|\s)RECORD[\s;]", "Code", wdBlue, selection_range)
        Call AssociateStyle("(^|\s)REBUILD[\s;]", "Code", wdBlue, selection_range)
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
        
   
        StraightenQuotes selection_range
       ColorComments selection_range
       
    End If
 
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


    Dim myInspector As Outlook.Inspector
    Dim myDoc As Word.Document
    Set myInspector = Application.ActiveInspector
    Set myDoc = myInspector.WordEditor

' Look for comments.
For Each para In rng.Paragraphs
        txt = para.Range.Text
        start_point = InStr(txt, "--")
        If start_point > 0 Then
            Set comment_range = myDoc.Range(para.Range.Start + start_point - 1, para.Range.Start + Len(txt))
            comment_range.Font.Color = wdColorGreen
            comment_range.Case = wdLowerCase
        End If
Next para

' look for  /*.....*/ comments
comment_open = False

For Each para In rng.Paragraphs
        txt = para.Range.Text
        
        start_point = 0
        end_point = 0
        end_point = InStr(txt, "*/")
        start_point = InStr(txt, "/*")
        
        If start_point > 0 And end_point = 0 Then
            Set comment_range = myDoc.Range(para.Range.Start + start_point, para.Range.End)
            comment_range.Font.Color = wdColorGreen
            comment_open = True
        End If
        
        
        If end_point > 0 And start_point = 0 Then
              Set comment_range = myDoc.Range(para.Range.Start, para.Range.Start + end_point + 2)
              comment_range.Font.Color = wdColorGreen
              comment_open = False
        End If
        

        If end_point > 0 And start_point > 0 Then
              Set comment_range = myDoc.Range(para.Range.Start + start_point, para.Range.Start + end_point)
              comment_range.Font.Color = wdColorGreen
              comment_open = False
        End If
        
        If comment_open = True And start_point = 0 And end_point = 0 Then
              para.Range.Font.Color = wdColorGreen
        End If
     
       
Next para

' look for strings contained inside single quotes
comment_open = False

For Each para In rng.Paragraphs
        txt = para.Range.Text
        
        start_point = 0
        start_point = InStr(txt, "'")
        If start_point > 0 Then
           If comment_open = True Then
              ' This is the end of an existing comment, finish it off
              end_point = InStr(txt, "'")
              Set comment_range = myDoc.Range(para.Range.Start, para.Range.Start + end_point)
              comment_range.Font.Color = wdColorOrange
              comment_open = False
              ' now repeat the check to see if we can find another instance of a quote
              start_point = InStr(end_point + 1, txt, "'")
            End If
        
            ' This is a new comment, find the end
            While start_point > 0
               comment_open = True
               end_point = InStr(start_point + 1, txt, "'")
               If end_point > 0 Then
                 ' we've found a closing quote, so close it
                  Set comment_range = myDoc.Range(para.Range.Start + start_point, para.Range.Start + end_point - 1)
                  comment_range.Font.Color = wdColorOrange
                  comment_open = False
               Else
                  ' deal with situation where comment has no end on this line
                  Set comment_range = myDoc.Range(para.Range.Start + start_point, para.Range.End)
                  comment_range.Font.Color = wdColorOrange
                  end_point = start_point
              End If
              ' now repeat the check to see if we can find another instance of a quote
              start_point = InStr(end_point + 1, txt, "'")
            Wend
 
        Else
          ' theres no quotes on this line, check if we are inside a multi-line quote
          If comment_open = True And InStr(txt, "'") = 0 Then
              para.Range.Font.Color = wdColorOrange
          End If
        End If
Next para


End Sub



' Replace curly quotes with straight quotes.
Public Sub StraightenQuotes(ByVal rng As Range)
Dim old_replace_quotes As Boolean

'    old_replace_quotes =  Options.AutoFormatAsYouTypeReplaceQuotes
'    Options.AutoFormatAsYouTypeReplaceQuotes = False

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

    'Options.AutoFormatAsYouTypeReplaceQuotes = old_replace_quotes
End Sub



Sub AssociateStyle(pattern As String, style As String, colour As Long, ByVal rng As Range)
'Associate Styles with headings and quotations
'Ensure Tools?References?Microsoft VBscript Regular Expression 5.5 is on


    Dim myInspector As Outlook.Inspector
    Dim myDoc As Word.Document
    Set myInspector = Application.ActiveInspector
    Set myDoc = myInspector.WordEditor


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
    Set region = myDoc.Range(rng.Start + Match.FirstIndex, rng.Start + Match.FirstIndex + Len(Match.Value))
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






