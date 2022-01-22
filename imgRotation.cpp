
// g++ -ggdb `pkg-config --cflags imgRotation.cpp` -o img `imgRotation.cpp` `pkg-config --libs opencv`
#include <opencv2/opencv.hpp>
#include "opencv2/imgproc.hpp"
#include "opencv2/highgui.hpp"

class ImgRotation{
    private:

    cv::Mat img;
    double angle;
    void rotation(cv::Mat scr, double angle ){
        cv::Point2f pt(scr.cols/2, scr.rows/2);
        cv::Mat temp = getRotationMatrix2D(pt, angle, 1.0);
        cv::warpAffine(scr, this->img, temp, cv::Size(scr.cols, scr.rows));
    }
    public:
    ImgRotation(cv::Mat scr, double angle){
        rotation(scr, angle);
    }
    cv::Mat get_rotated_img(){
        return img;
    }
};


int main(){
    cv::Mat scr=cv::imread("./spatial_transformer.png");
    ImgRotation img(scr, 30);
    cv::imshow("source:", scr);
    cv::imshow("rotated:", img.get_rotated_img());
    cv::waitKey(0);
    return 0;
}