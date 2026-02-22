
#ifndef Raw2Dng_hpp
#define Raw2Dng_hpp

#include <string>
#include "rawConverter/rawConverter.h"

class Raw2DngConverter
{
public:
    bool raw2dng(const std::string& rawFilename, const std::string& outFilename);
    
};


#endif
