/*!
  \~japanese
  \example get_distance.cpp 距離データを取得する
  \~english
  \example get_distance.cpp Obtains distance data
  \~
  \author Satofumi KAMIMURA

  $Id$
*/

#include "Urg_driver.h"
#include "Connection_information.h"
#include "math_utilities.h"
#include <iostream>

using namespace qrk;
using namespace std;


namespace
{
    void print_data(const Urg_driver& urg,
                    const vector<long>& data, long time_stamp)
    {
    // \~japanese 全てのデータの X-Y の位置を表示
    // \~english Prints the X-Y coordinates for all the measurement points
        size_t data_n = data.size();
        cout << time_stamp << endl;
        for (size_t i = 0; i < data_n; ++i) {
            long l = data[i];
            double radian = urg.index2rad(i);
            long x = static_cast<long>(l * cos(radian));
            long y = static_cast<long>(l * sin(radian));
            cout << x << " " << y << endl;
        }
    }
}


int main(int argc, char *argv[])
{
    Connection_information information(argc, argv);

    // \~japanese 接続
    // \~english Connects to the sensor
    Urg_driver urg;
    if (!urg.open(information.device_or_ip_name(),
                  information.baudrate_or_port_number(),
                  information.connection_type())) {
        cout << "Urg_driver::open(): "
             << information.device_or_ip_name() << ": " << urg.what() << endl;
        return 1;
    }

    // \~japanese データ取得
    // \~english Gets measurement data
    enum { Capture_times = 1200};
    urg.start_measurement(Urg_driver::Distance, Urg_driver::Infinity_times, 0);
    for (int i = 0; i < Capture_times; ++i) {
        vector<long> data;
        long time_stamp = 0;

        if (!urg.get_distance(data, &time_stamp)) {
            cout << "Urg_driver::get_distance(): " << urg.what() << endl;
            return 1;
        }
        print_data(urg, data, time_stamp);
    }
    return 0;
}
