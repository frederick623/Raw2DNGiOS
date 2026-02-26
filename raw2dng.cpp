
#include "raw2dng.hpp"

std::string Raw2DngConverter::raw2dng(const std::string& rawFilename, const std::string& outFilename)
{
    RawConverter converter;
    try{
        converter.openRawFile(rawFilename);
        converter.buildNegative("");
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
