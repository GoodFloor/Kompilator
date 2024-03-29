#include <fstream>
#include <map>
#include <sstream>
#include "utils.hpp"
#include <iostream>

std::string intToBinary(unsigned long long n)
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

std::string insertingNumber(std::string r, unsigned long long number)
{
    std::string commands;
    std::string n = intToBinary(number);

    commands += "RST " + r + "\n";
    for(int i = 0; i < n.size(); i++)
    {
        if(i > 0)
            commands += "SHL " + r + "\n";
        if(n[i] == '1')
            commands += "INC " + r + "\n";
    } 
    return commands;
}

std::string fillJumps(std::string instructionBlock)
{
    int currentLine = 0;
    std::map<std::string, int> jumpAddress;
    std::stringstream ss(instructionBlock);
    std::string oneLine = "";

    // Szukanie adresów docelowych dla skoków
    while (getline(ss, oneLine))
    {
        if (oneLine[0] == '#')
            continue;
        else if (oneLine[0] == '@')
            jumpAddress[oneLine] = currentLine;
        else
            currentLine++;
    }

    // Uzupełnianie skoków
    ss = std::stringstream(instructionBlock);
    std::string result = "";
    while (getline(ss, oneLine))
    {
        if (oneLine.substr(0, 5) == "JUMP " || oneLine.substr(0, 5) == "JPOS " || oneLine.substr(0, 6) == "JZERO ")
        {
            int at = oneLine.find("@");
            if (at > -1)
                result += oneLine.substr(0, at) + std::to_string(jumpAddress[oneLine.substr(at)]) + "\n";
            else 
                result += oneLine + "\n";
        }
        else if (oneLine[0] != '@')
            result += oneLine + "\n";
    }
    return result;
}

void printCmd(std::string pseudocode, std::string outputFile)
{
    std::fstream output;
    output.open(outputFile, std::ios::out);
    if (!output.good())
        throw "Nie udało się utworzyć pliku wynikowego";
    output << fillJumps(pseudocode);
    output.close();
}
