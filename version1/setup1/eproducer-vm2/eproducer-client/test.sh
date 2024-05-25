export input="[let,see,how,goes]"
#remove brackets
export intinput=${input:1:-1}
#change commas into pluses
export int2input="${intinput//,/+}"
#remove quotation marks
export int3input="${int2input//\"/}"
#re-add outside quotationmarks
export finalinput="\"$int3input\""
echo $finalinput