#include <algorithm>
#include "utils.hpp"

std::string intToBinary(int n)
{
    std::string result = "";
    while (n > 0)
    {
        if (n % 2 == 0)
        {
            result = "0" + result;
        }
        else
        {
            result = "1" + result;
        }
        n /= 2;    
    }
    return result;    
}

int countLines(std::string s)
{
    return std::count(s.begin(), s.end(), '\n');
}

int insertingNumber(std::string r, int number, std::string* target)
{
    std::string commands;
    std::string n = intToBinary(number);
    int generatedLines = 0;
    *target += "RST " + r + "\n";
    generatedLines++;
    for(int i = 0; i < n.size(); i++)
    {
        if(i > 0)
        {
            *target += "SHL " + r + "\n";
            generatedLines++;
        }
        if(n[i] == '1')
        {
            *target += "INC " + r + "\n";
            generatedLines++;
        }
    } 
    return generatedLines;
}
