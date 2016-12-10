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
#include <signal.h>

using namespace qrk;
using namespace std;

Urg_driver urg;

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

void handler(int s) {
    cout << "stop: " << s << endl;
    urg.stop_measurement();
    urg.close();
    exit(0);
}


int main(int argc, char *argv[])
{
    // Connection_information information(argc, argv);

    // \~japanese 接続
    // \~english Connects to the sensor
    if (!urg.open("192.168.0.10", 10940, Urg_driver::Ethernet)) {
        cout << "Urg_driver::open(): " << ": " << urg.what() << endl;
        return 1;
    }

    int capture_times = 0, skip_scan = 0;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "-t")) {
            capture_times = atoi(argv[i + 1]);
        }
        if (!strcmp(argv[i], "-s")) {
            skip_scan = atoi(argv[i + 1]);
        }
    }
    // \~japanese データ取得
    // \~english Gets measurement data
    urg.start_measurement(Urg_driver::Distance, capture_times, skip_scan);
    signal(SIGINT, handler);
    int capture_count = 0;
    while (true) {
        if (capture_times > 0 && capture_count == capture_times) break;
        vector<long> data;
        long time_stamp = 0;

        if (!urg.get_distance(data, &time_stamp)) {
            cout << "Urg_driver::get_distance(): " << urg.what() << endl;
            return 1;
        }
        print_data(urg, data, time_stamp);
        capture_count++;
    }
    urg.stop_measurement();
    urg.close();
    return 0;
}
