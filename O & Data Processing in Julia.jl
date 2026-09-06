#=
this can make your program read data from disk
process it, and save the result back to disk

1. reading the entire text file
content=read("data.txt",String) -> the return value is a single String

2. reading a file line by line
lines = readlines("data.txt")

Not suggested!!!!!!
3. writing to a file -> it will cover the things that are already in the file, such fucking terrible
write("path","content") -> return the number of input in char

4. append
open("log.txt", "a") do io
    write(io, "New log entry\n")
end

5. CSV files -> Comma-Separated Values
using CSV
using DataFrames
df=CSV.read("path",DataFrame) -> DataFrame is the format of data

6. Writing a DataFrame to CS
CSV.write("path",filename) -> I think it's useless, maybe copy

7. JSON -> another common data format
8. Writing JSON
data=Dict(
    "name"=>"Alice",
    "age"=>20
)
open("path","w") do io
    JSON.print(io,data)
end
_=JSON.parsefile("path")

9. Saving Julia objects directly

10. String operations
s = "a,b,c"
split(s, ",") -> ["a", "b", "c"]

11. join
names = ["Alice", "Bob", "Charlie"]
join(names, ",") -> "Alice,Bob,Charlie"

12. replace -> use in String
text = "Hello World"
replace(text, "World" => "Julia")

13. strip -> remove whitespace from the beginning and end of the String
text = "   Hello Julia   "
strip(text)

=#

# I think it is too slow, String is more usable
content=read("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test.txt",String)
length(content)
open("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test.txt","a") do io
    println(io,"I am learning julia")
    println(io,"I will never give up!")
    println(io,"be brave to grasp opportunities")
end
line = readlines("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test.txt")
line # one-dimension array = vector
for i in line
    println("what I said: ",i)
end
write("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test.txt","will it change the line?")
open("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test.txt", "a") do io
    write(io, "New log entry\n")
end
using CSV
using DataFrames
df=CSV.read("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test.txt",DataFrame) # it is not good example
open("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test1.txt","a") do io
    println(io,"name,age,score")
    println(io,"Alice,20,85")
    println(io,"Bob,21,91")
    println(io,"Charlie,19,78")
end
df1=CSV.read("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test1.txt",DataFrame)
df1.score
using Statistics
mean(df1.score) # get the avarage
CSV.write("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test2.txt",df1)
# create a DataFrame
DataFrame(course=[7710,6260,6390])
DataFrame(course=[7710,6260,6390];grade=[70,57,35])
using JSON
info=JSON.Dict(
    "name"=>"Yan Tong",
    "age"=>21,
    "sex"=>"male",
    "uni"=> "anu"
)
open("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test3.txt","w") do io
    JSON.print(io,info)
end
data=JSON.parsefile("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test3.txt")
A = rand(10000, 10000) # rows and columns
using JLD2
@save "C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test5.txt" A
@load "C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/test5.txt" A
size(A)
A[1:3,1:3] # row,column
data1 = "Alice,20,85"
fields = split(data1, ",")
fields
arr10=["java","python","julia"]
join(arr10,",")
str="java"
str=replace(str,"java"=>"julia")
str
s1="            ikcbvet bvg b rtf brd b srtd gbrt db esr nh            "
strip(s1)

#=
14. Putting everything together
Read a CSV → calculate the average of a column → write the result to a new file.
=#
open("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/students.csv","w") do io
    println(io,"name,score")
    println(io,"Alice,85")
    println(io,"Bob,90")
    println(io,"Charlie,75")
    println(io,"David,95")
end
using CSV
using DataFrames
using Statistics
df5=CSV.read("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/students.csv",DataFrame)
as=mean(df5.score)
result = DataFrame(as = [as])
CSV.write("C:/颜-个人/澳洲，新西兰，爱尔兰/Australia/国立/CoursePPT/Julia/result.csv",result)