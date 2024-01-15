CFLAGS 	 += -O3
CXXFLAGS += -std=c++0x
FLEXFLAGS = 
# FLEXFLAGS+= -d

CC        = gcc $(CFLAGS)
CXX       = g++ $(CFLAGS) $(CXXFLAGS)

all: kompilator

kompilator: kompilator_y.cpp kompilator_l.cpp
	$(CXX) -o kompilator kompilator_y.cpp kompilator_l.cpp

kompilator_y.cpp: kompilator.y
	bison -o kompilator_y.cpp -d kompilator.y 

kompilator_l.cpp: kompilator.lex
	flex -o kompilator_l.cpp $(FLEXFLAGS) kompilator.lex

clean:
	rm -f *.cpp *.o *.hpp *.h

cleanall: clean
	rm -f kompilator
