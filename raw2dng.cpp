
#include "raw2dng.hpp"

bool Raw2DngConverter::raw2dng(const std::string& rawFilename, const std::string& outFilename)
{
    RawConverter converter;
    converter.openRawFile(rawFilename);
    converter.buildNegative("");
    // if (embedOriginal) converter.embedRaw(rawFilename);
    converter.renderImage();
    converter.renderPreviews();
    converter.writeDng(outFilename);
    return true;
}
