# if / elseif / else
function ff(x)
    if 20>x>10
        return x*0.2
    elseif 40>x>30
        return x*0.4
    elseif 80>x>50
        return x*0.8
    else
        return x
    end
end
x=100
ff(100)
ff(60)


# Conditions are Boolean expressions
# Ternary operator ? :
function f2(x)
    x=x>100 ? x+1000 : x-1000
    return x
end
f2(10)


# for loops
x=0
for i in 1:5
    x=x+i
end
x


# Step ranges -> start:step:stop
for i in 1:2:10
    print(i)
end
for i in 1:-2:10
    print(i)
end


# Looping through an array
arr=["java","pythone","julia","c++","c"]
for i in arr
    print(i," ")
end
for i in 1:length(arr)
    print(arr[i]," ")
end


# value + index
for (i, x) in enumerate(arr)
    println("index = ", i, ", value = ", x)
end
enumerate(arr)


# safer index traversal -> using arr[i] iterate
# Parallel iteration with zip
names = ["Alice", "Bob", "Charlie"]
scores = [90, 85, 95]
for i in eachindex(names)
    println("name: ",names[i]," ","scores: ",scores[i])
end
for (name,score) in zip(names,scores)
    println(name,": ",score)
end
zip(names,scores)
enumerate(arr)


# while loops
function f3(x)
    y=0
    while x < 100
       y=y+x
       x+=1
    end
    return y
end
f3(1)


# break
function f4(x)
    while x < 100
       x+=1
       if x ==50
        break
       end
    end
    return x
end
f4(1)
f4(50)


# continue
function f5(x)
    y=0
    while x < 100
        x+=1
        if x%2==0
         continue
        else
         y=y+x
       end
    end
    return y
end
f5(0)


# Nested loops
for i in 1:2
    for j in 1:10
        println(i," ",j)
    end
end


# Find the maximum value
arr1=[3, 7, 2, 10, 5]
max=arr1[1]
for i in 1:length(arr1)
    max = max<arr1[i] ? arr1[i] : max
end
max


# leapYear simple do not write