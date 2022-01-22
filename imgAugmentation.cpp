
// g++ -ggdb `pkg-config --cflags imgRotation.cpp` -o img `imgRotation.cpp` `pkg-config --libs opencv`
#include <opencv2/opencv.hpp>
#include "opencv2/imgproc.hpp"
#include "opencv2/highgui.hpp"

class ImgAugmentation{
    private:

    cv::Mat img;
    double angle;
    void rotation(cv::Mat scr, double angle ){
        cv::Point2f pt(scr.cols/2, scr.rows/2);
        cv::Mat temp = getRotationMatrix2D(pt, angle, 1.0);
        cv::warpAffine(scr, this->img, temp, cv::Size(scr.cols, scr.rows));
    }
    void flipping(cv::Mat scr, char direction){
        if(direction==0 || direction==1 || direction==-1){
             cv::flip(scr, this->img, direction);
        }else{
            std::cout<<"please, select a valid selection value '0', '1' or '-1' "<<std::endl;
            throw("please, select a valid selection value '0', '1' or '-1' ");
        }

    }
    void shear(const cv::Mat & input, float Bx, float By){
        if (Bx*By == 1)
        {
            throw("Shearing: Bx*By==1 is forbidden");
        }

        if (input.type() != CV_8UC3) {
            throw("not valid type");
        }

        // shearing:
        // x'=x+y·Bx
        // y'=y+x*By

        // shear the extreme positions to find out new image size:
        std::vector<cv::Point2f> extremePoints; //vector<(0,1)>
        extremePoints.push_back(cv::Point2f(0, 0));
        extremePoints.push_back(cv::Point2f(input.cols, 0));
        extremePoints.push_back(cv::Point2f(input.cols, input.rows));
        extremePoints.push_back(cv::Point2f(0, input.rows));

        for (unsigned int i = 0; i < extremePoints.size(); ++i)
        {
            cv::Point2f & pt = extremePoints[i];
            pt = cv::Point2f(pt.x + pt.y*Bx, pt.y + pt.x*By);
        }

        cv::Rect offsets = cv::boundingRect(extremePoints);

        cv::Point2f offset = -offsets.tl();
        cv::Size resultSize = offsets.size();

        this->img = cv::Mat::zeros(resultSize, input.type()); // every pixel here is implicitely shifted by "offset"

        // perform the shearing by back-transformation
        for (int j = 0; j < img.rows; ++j)
        {

            for (int i = 0; i < img.cols; ++i)
            {
                cv::Point2f pp(i, j);

                pp = pp - offset; // go back to original coordinate system

                // go back to original pixel:
                // x'=x+y·Bx
                // y'=y+x*By
                //   y = y'-x*By
                //     x = x' -(y'-x*By)*Bx
                //     x = +x*By*Bx - y'*Bx +x'
                //     x*(1-By*Bx) = -y'*Bx +x'
                //     x = (-y'*Bx +x')/(1-By*Bx)

                cv::Point2f p;
                p.x = (-pp.y*Bx + pp.x) / (1 - By*Bx);
                p.y = pp.y - p.x*By;

                if ((p.x >= 0 && p.x < input.cols) && (p.y >= 0 && p.y < input.rows))
                {
                    // TODO: interpolate, if wanted (p is floating point precision and can be placed between two pixels)!
                    img.at<cv::Vec3b>(j, i) = input.at<cv::Vec3b>(p);
                }
            }
        }

}
    public:
    ImgAugmentation(cv::Mat scr, double angle, char direction, float bx, float by ){
        //rotation(scr, angle);
        //flipping(scr, direction);
        shear(scr, bx,by);
    }
    cv::Mat get_rotated_img(){
        return img;
    }
};


int main(){
    cv::Mat scr=cv::imread("./spatial_transformer.png");
    if( !scr.data )
    {
        std::cout<<"Error loadind src n"<<std::endl;
        return -1;
    }
    ImgAugmentation img(scr,30, 2, 0.7, 0);
    cv::imshow("source:", scr);
    cv::imshow("rotated:", img.get_rotated_img());
    cv::waitKey(0);
    return 0;
}