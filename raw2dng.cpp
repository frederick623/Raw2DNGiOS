
#include "raw2dng.hpp"

std::string Raw2DngConverter::raw2dng(const std::string& rawFilename, const std::string& outFilename)
{
    try{
        RawConverter converter(rawFilename, "");
        // if (embedOriginal) converter.embedRaw(rawFilename);
        converter.renderImage();
        converter.renderPreviews();
        converter.writeDng(outFilename);
    } catch (const std::exception& e)
    {
        return e.what();
    }
    return "";
}
