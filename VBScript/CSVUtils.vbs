'VBScript Version
'  Error is always Fatal.
'  Array always starts with index 0

'Attribute VB_Name = "CSVUtils"
'
' VBA-CSV
'
' Copyright (C) 2017- sdkn104 ( https://github.com/sdkn104/VBA-CSV/ )
'
' License MIT (http://www.opensource.org/licenses/mit-license.php)
'
'Option Explicit


'----- Global variables -------------------------------------------------------------

Private CSVUtilsAnyErrorIsFatal   'default False


'----- ERROR HANDLER ----------------------------------------------------------------

'
' Error function
'
Private Sub ErrorRaise(code , src , msg )
  ' raise only if this is the first error
  If Err.Number = 0 Then Err.Raise code, src, msg
End Sub

'
' Setting error handling mode
'
'  False (default) --- When run-time error occurs, the parser function returns special value (Nothing,  Null, etc.),
'                      and the error information is set to properties of Err object.
'  True            --- Any run-time error that occurs is fatal (an error message is displayed and execution stops).
'
Public Sub SetCSVUtilsAnyErrorIsFatal(ByRef value )
  CSVUtilsAnyErrorIsFatal = value
End Sub


'------ Public Function/Sub --------------------------------------------------------

'
' Parse CSV text returning Collection
'
'   Return a Collection of records each of which is a Collection of fields
'   When error, return Nothing
'
Public Function ParseCSVToCollection(ByRef csvText ) 
    ' "'On Error 'Resume Next" only if CSVUtilsAnyErrorIsFatal is True
    Err.Clear
'    If CSVUtilsAnyErrorIsFatal Then GoTo Head
    'On Error 'Resume Next
'Head:
    Dim csvPos 
    Dim recordPos 
    Dim recordText , recordTextComma 
    Dim fieldText 
    Dim fields 
    Dim csvCollection 
    Set csvCollection = New Collection 'empty collection
    
    Set ParseCSVToCollection = csvCollection
    
    'for empty text
    If csvText = "" Then Exit Function 'return empty collection
    
    'extract records and fields
    csvPos = 1
    Do While GetOneRecord(csvText, csvPos, recordText)
        Set fields = New Collection
        recordPos = 1
        recordTextComma = recordText & ","
        Do While FindNextSeparator(recordTextComma, recordPos, fieldText, ",", "")
            If InStr(fieldText, """") > 0 Then
              fieldText = TrimQuotes(fieldText) 'get internal of double-quotes
              fieldText = Replace(fieldText, """""", """") 'un-escape double quote
              If Left(fieldText, 2) = "=""" And Right(fieldText, 1) = """" Then fieldText = Mid(fieldText, 3, Len(fieldText) - 3) 'remove MS quote (="...")
            End If
            'add to collection
            fields.Add fieldText
        Loop
        csvCollection.Add fields
        
        If csvCollection.Item(1).Count <> fields.Count Then
            ErrorRaise 10001, "ParseCSVToCollection", "Syntax Error in CSV: numbers of fields are different among records"
'            GoTo ErrorExit
        End If
    Loop
'    If Err.Number <> 0 Then GoTo ErrorExit
    
    Set ParseCSVToCollection = csvCollection
    Exit Function

'ErrorExit:
    Set ParseCSVToCollection = Nothing
End Function

'
' Parse CSV text and return 2-dim array
'
'  Return 2-dim array --- String(1 TO recordCount, 1 TO fieldCount)
'  When CSV text is "", return empty array --- String(0 TO -1)
'  When error, return Null
'
Public Function ParseCSVToArray(ByRef csvText ) 
    ' "'On Error 'Resume Next" only if CSVUtilsAnyErrorIsFatal is True
    Err.Clear
'    If CSVUtilsAnyErrorIsFatal Then GoTo Head
    'On Error 'Resume Next
'Head:
    Dim csv 
    Dim recCnt , fldCnt 
    Dim csvArray() 
    Dim ri , fi 
    Dim rc , cc 
    
    ParseCSVToArray = Null 'for error
  
    ' convert CSV text to Collection
    Set csv = ParseCSVToCollection(csvText)
    If csv Is Nothing Then  'error occur
        Exit Function
    End If
    
    ' get size of collections
    recCnt = csv.Count
    If recCnt = 0 Then
        ParseCSVToArray = Split("", "/") 'return empty(zero length) String array of bound 0 TO -1
                                         '(https://msdn.microsoft.com/ja-jp/library/office/gg278528.aspx)
        Exit Function
    End If
    fldCnt = csv.Item(1).Count
    
    ' copy collection to array
    ReDim csvArray(recCnt-1, fldCnt-1) 
    ri = 1
    For rr = 1 To recCnt : ri = rr-1 'For Each rc In csv 'for each is faster for Collection
      fi = 1
      For ff = 1 To fldCnt : fi = ff-1 : cc = csv.Item(rr).Item(ff) 'For Each cc In rc
        csvArray(ri, fi) = cc
        fi = fi + 1
      Next
      ri = ri + 1
    Next
    
    ParseCSVToArray = csvArray
End Function


'
' Convert 2-dim array to CSV text string
'
'  inArray : 2-dim array of arbitary size/range and type.
'  fmtDate : format used for conversion from type Date to type String
'  When error, return ""
'
Public Function ConvertArrayToCSV(inArray , fmtDate) 
    ' "'On Error 'Resume Next" only if CSVUtilsAnyErrorIsFatal is True
    Err.Clear
'    If CSVUtilsAnyErrorIsFatal Then GoTo Head
    'On Error 'Resume Next
'Head:
    Dim csv 
    Dim r , c , ub2 
    Dim v 
    Dim cell 
    Dim arrRecord , arrField 
    
    'error check
    If Not IsArray(inArray) Then
        ErrorRaise 10004, "ConvertArrayToCSV", "Input argument inArray is not array"
'        GoTo ErrorExit
    End If
    ub2 = UBound(inArray, 2)
    If Err.Number <> 0 Then 'expecting Err.Number = 9, Err.Description = "Subscript out of range", for inArray is 1-dim
'        GoTo ErrorExit
    End If

    Dim rc , cc 
    ReDim arrRecord((UBound(inArray, 1))-(LBound(inArray, 1)))  'temporary array
    ReDim arrField((UBound(inArray, 2))-(LBound(inArray, 2)))  'temporary array
    
    For r = LBound(inArray, 1) To UBound(inArray, 1)
      For c = LBound(inArray, 2) To UBound(inArray, 2)
        v = inArray(r, c)
        'formatting
        cell = v
        If TypeName(v) = "Date" Then cell = Format(v, fmtDate)
        'quote and escape
        If InStr(cell, ",") > 0 Or InStr(cell, """") > 0 Or InStr(cell, vbCr) > 0 Or InStr(cell, vbLf) > 0 Then
          cell = Replace(cell, """", """""")
          cell = """" & cell & """"
        End If
        'add to array
        arrField(c) = cell
      Next
      arrRecord(r) = Join(arrField, ",") & vbCrLf
    Next
'    If Err.Number <> 0 Then GoTo ErrorExit 'unexpected error
    
    ConvertArrayToCSV = Join(arrRecord, "")
    Exit Function
'ErrorExit:
    ConvertArrayToCSV = ""
End Function


' ------------- Private function/sub ---------------------------------------------------------------------

'
' Get the next one record from csvText, and put it into recordText
'     updating csvPos
'
Private Function GetOneRecord(ByRef csvText , ByRef csvPos , ByRef recordText ) 
  GetOneRecord = FindNextSeparator(csvText, csvPos, recordText, "" & vbCr, "" & vbLf)
  If Not GetOneRecord Then Exit Function
  If Mid(csvText, csvPos - 1, 2) = vbCr & vbLf Then csvPos = csvPos + 1 'for CR+LF
End Function

' Find next separator in inText starting with the position "start"
'   foundText = substring [start, found_separator-1] of inText
'   start = found_separator + 1
'   assume that a virtual separator exists at the end of string if there is no separator there.
Private Function FindNextSeparator(ByRef inText , ByRef start , ByRef foundText , ByRef sep1 , sep2) 
    Dim dQuateCnt 
    Dim init_start , lenText , p2 , found 
    
    FindNextSeparator = False
    lenText = Len(inText)
    init_start = start
        
    If start > lenText Then Exit Function 'over-run
    
    dQuateCnt = 0
    Do While start <= lenText
        'find next separator
        found = InStr(start, inText, sep1)
        If sep2 <> "" Then
          p2 = InStr(start, inText, sep2)
          If p2 <> 0 And (found = 0 Or p2 < found) Then found = p2
        End If
        If found = 0 Then found = lenText + 1 'EOF
                
        dQuateCnt = dQuateCnt + StrCount(inText, """", start, found - 1) 'number of double quates in inText
        start = found + 1
        If dQuateCnt Mod 2 = 0 Then  'if the number of double-quates is even, then the separator is not fake
            FindNextSeparator = True
            foundText = Mid(inText, init_start, found - init_start)
            Exit Function
        End If
    Loop
    
    ErrorRaise 10002, "ParseCSVToCollection", "Syntax Error in CSV: illegal double-quote code"
End Function



'
' count the string Target in [p0, p1] of Source
'
Private Function StrCount(Source , Target , p0 , p1 ) 
    Dim n , cnt 
    n = p0 - 1
    cnt = 0
    Do
        n = InStr(n + 1, Source, Target)
        If n = 0 Or n > p1 Then Exit Do
        cnt = cnt + 1
    Loop
    StrCount = cnt
End Function

'
' Trim all before and after doube-quote
'   * text MUST include two or more double-quotes (")
Private Function TrimQuotes(ByRef text ) 
    'If InStr(text, """") = 0 Then Err.Raise 9999, "", "program error"
    Dim p0 , p1 
    Dim s 
    
    'trim tail
    For p1 = Len(text) To 1 Step -1
      s = Mid(text, p1, 1)
      If (s = """") Then Exit For
    Next
    'trim head
    For p0 = 1 To p1
      s = Mid(text, p0, 1)
      If (s = """") Then Exit For
    Next
    'return
    TrimQuotes = Mid(text, p0 + 1, p1 - p0 - 1)
End Function


'Definitions for VBScript
'#If 0 Then
Function Mid(t, s, l)
  Mid = Left(t, s + l - 1)
  Mid = Right(Mid, l)
End Function

Function Format(date, fmt)
  r = fmt
  r = Replace(r, "yyyy", Year(Date))
  r = Replace(r, "mm", Left("0" & Month(Date), 2))
  r = Replace(r, "dd", Left("0" & Day(Date), 2))
  r = Replace(r, "m", "" & Month(Date))
  r = Replace(r, "d", "" & Day(Date))
  Format = r
End Function

Class Collection
  Dim Item(100000)
  Dim Count
  Sub Class_Initialize()
    Count = 0
  End Sub
  Sub Add(val)
    Count = Count + 1
    If IsObject(val) Then
      Set Item(Count) = val
    Else
      Item(Count) = val
    End If
  End Sub
End Class
'#End If
