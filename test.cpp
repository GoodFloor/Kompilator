#include <iostream>
#include <sstream>
#include "utils.hpp"

using namespace std;

int main(int argc, char const *argv[])
{
    string multiline = "INS1\nINS2\nJUMP @ADDR1\nJZERO @ADDR2\nJPOS @ADDR3\n@ADDR1\n#komentarz\n@ADDR2\nINS3\n@ADDR3\n";
    cout << "Before:" << endl << multiline << endl << "After:" << endl << fillJumps(multiline) << endl;
    return 0;
}
