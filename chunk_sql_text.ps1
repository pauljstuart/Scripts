
$counter = 0
$num_blocks = 0
$limit = 30000

Clear-Content myoutput.txt

"Starting block $num_blocks"
Add-Content myoutput.txt  "sqltext_clob$num_blocks := q`'#"
foreach($line in [System.IO.File]::ReadLines("C:\users\pauls\documents\gpgnet0.log"))
{
      Add-Content myoutput.txt  $line
      $counter = $counter + $line.length
      if ($counter -gt $limit) 
         {
         $num_blocks = $num_blocks + 1
         "Block $num_blocks"
         Add-Content myoutput.txt  "#`';"
         Add-Content myoutput.txt  `n`n
         Add-Content myoutput.txt  "sqltext_clob$num_blocks := q`'#"
         $counter = 0
         }
}

Add-Content myoutput.txt  "#`';"
