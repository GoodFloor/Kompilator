CFLAGS 	 += -O3
CXXFLAGS += -std=c++0x
FLEXFLAGS = 
# FLEXFLAGS+= -d

CC        = gcc $(CFLAGS)
CXX       = g++ $(CFLAGS) $(CXXFLAGS)

all: kompilator

kompilator: kompilator_y.o kompilator_l.o utils.o 
	$(CXX) -o kompilator kompilator_l.o kompilator_y.o utils.o 

%.o: %.cpp
	$(CXX) -c $^
	
kompilator_y.hpp: kompilator_y.cpp

kompilator_y.cpp: kompilator.y
	bison -o kompilator_y.cpp -d kompilator.y 

kompilator_l.cpp: kompilator.lex
	flex -o kompilator_l.cpp $(FLEXFLAGS) kompilator.lex

clean:
	rm -f kompilator_l.cpp kompilator_l.hpp kompilator_y.cpp kompilator_y.hpp *.o

cleanall: clean
	rm -f kompilator
