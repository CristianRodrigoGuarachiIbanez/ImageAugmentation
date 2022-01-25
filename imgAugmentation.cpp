
// g++ imgRotation.cpp` -o img `pkg-config --libs opencv` ggdb `pkg-config --cflags  `imgRotation.cpp`
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
        //https://stackoverflow.com/questions/46998895/image-shearing-c
        if (Bx*By == 1)
        {
            std::cout<<"Shearing: Bx*By==1 is forbidden"<<std::endl;
            throw("Shearing: Bx*By==1 is forbidden");
        }

        if (input.type() == CV_8UC3 || input.type() ==CV_8UC2) {
            std::cout<<"not valid type"<<":" <<input.type()<<" "<< "valid type:"<< CV_8UC1 <<std::endl;
            throw("not valid type");
        }
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

        cv::Rect offsets = cv::boundingRect(extremePoints); //[900 x 283 from (0, 0)]

        cv::Point2f offset = -offsets.tl(); //[0, 0]
        cv::Size resultSize = offsets.size();//[900 x 283]

        this->img = cv::Mat::zeros(resultSize, input.type()); // every pixel here is implicitely shifted by "offset"

        // perform the shearing by back-transformation
        for (int j = 0; j < img.rows; ++j)
        {
            for (int i = 0; i < img.cols; ++i)
            {
                cv::Point2f pp(i, j);
                pp = pp - offset; // go back to original coordinate system

                // go back to original pixel:

                cv::Point2f p;
                p.x = (-pp.y*Bx + pp.x) / (1 - By*Bx);
                p.y = pp.y - p.x*By;

                if ((p.x >= 0 && p.x < input.cols) && (p.y >= 0 && p.y < input.rows))
                {
                    // TODO: interpolate, if wanted (p is floating point precision and can be placed between two pixels)!
                    //img.at<cv::Vec3b>(j, i) = input.at<cv::Vec3b>(p);
                    img.at<uchar>(j,i) = input.at<uchar>(p);
                    std::cout<<img.at<uchar>(j, i)<<std::endl;
                }
            }
        }
    }
    void cropping(cv::Mat image, const int cropSize){

        const int offsetW = (image.cols - cropSize) / 2;
        const int offsetH = (image.rows - cropSize) / 2;
        const cv::Rect roi(offsetW, offsetH, cropSize, cropSize);
        this->img= image(roi).clone();
        std::cout << "Cropped image dimension: " << image.cols << " X " << image.rows << std::endl;

    }
    void changing_contrast_brightness(cv::Mat image, double alpha, int beta){

    this->img = cv::Mat::zeros( image.size(), image.type() );
        for(int y =0; y<image.rows; y++){
            for(int x =0;x<image.cols;x++ ){
                img.at<uchar>(y,x) = cv::saturate_cast<uchar>(alpha*image.at<uchar>(y,x) + beta);
                //for(int c=0; c<image.channels(); c++){
                    //std::cout<< cv::saturate_cast<uchar>( alpha*image.at<uchar>(y,x) + beta )<<std::endl;
                    //img.at<cv::Vec3b>(y,x)[c]=cv::saturate_cast<uchar>( alpha*image.at<cv::Vec3b>(y,x)[c] + beta);
                //}
            }
        }
    }
    public:
    ImgAugmentation(cv::Mat scr, double angle, char direction, float bx, float by ){
        //rotation(scr, angle);
        //flipping(scr, direction);
        //shear(scr, bx,by);
       //cropping(scr, 128);
       //changing_contrast_brightness(scr, 2.0, 2);
    }
    cv::Mat get_rotated_img(){
        return img;
    }
};


int main(){
    cv::Mat scr=cv::imread("./spatial_transformer.png", cv::IMREAD_GRAYSCALE);
    if( !scr.data )
    {
        std::cout<<"Error loadind src n"<<std::endl;
        return -1;
    }
    std::cout<<scr.type() <<" "<<CV_8UC1<<std::endl;
    ImgAugmentation img(scr,30.0, 2, 0.7, 0);
    cv::imshow("source:", scr);
    cv::imshow("rotated:", img.get_rotated_img());
    cv::waitKey(0);
    return 0;
}