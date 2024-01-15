#include <string>

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