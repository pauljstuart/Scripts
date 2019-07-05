

-- vba macro to parse a block sql text and chunk it in to 30,000 character blocks



Public Sub ParseLines()
    Dim singleLine As Paragraph
    Dim lineText As String
    Dim i_line_count
    Dim i_total_block_size
    Dim s_output_text
Dim selection_range As Range

i_lines = Selection.Range.ComputeStatistics(Statistic:=wdStatisticLines)
i_characters = Selection.Range.ComputeStatistics(Statistic:=wdStatisticCharacters)

s_output_text = s_output_text & Chr(10) & "----------------------------" & Chr(10)
s_output_text = s_output_text & i_lines & " lines. " & Chr(10)
s_output_text = s_output_text & i_characters & " characters. " & Chr(10)
s_output_text = s_output_text & "----------------------------" & Chr(10)

i_line_count = 0
i_block_num = 2
i_total_block_size = 0
s_output_text = s_output_text & Chr(10) & Chr(10) & "sql_text_clob1 CLOB := q'# " & Chr(10)

' Get the selected range.
Set selection_range = Selection.Range
    
    For Each singleLine In ActiveDocument.Paragraphs
        lineText = singleLine.Range.Text
        s_output_text = s_output_text & singleLine.Range.Text
        i_total_block_size = i_total_block_size + Len(lineText)
        If i_total_block_size > 30000 Then
            s_output_text = s_output_text & Chr(10) & "#';" & Chr(10) & Chr(10)
            s_output_text = s_output_text & Chr(10) & Chr(10) & "sql_text_clob" & i_block_num & " CLOB := q'# " & Chr(10)
            i_total_block_size = 0
            i_block_num = i_block_num + 1
        End If
    Next singleLine
    
    s_output_text = s_output_text & Chr(10) & "#';" & Chr(10) & Chr(10)
    
    Documents.Add
    ActiveDocument.Content.InsertAfter s_output_text
    ActiveDocument.Content.style = ActiveDocument.Styles("Code")
    
End Sub
