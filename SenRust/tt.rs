use std::io;
fn read_line() {
    let mut buffer = String::new();
    loop {
        match io::stdin().read_line(&mut buffer) {
            Ok(l) if l == 0 => break, // EOF
            Ok(_) => {},
            Err(_) => panic!("Failed to read line"),
        }
        println!("{}", buffer);
    }
}

#[derive(Debug)]
struct Point {
    x: i32,
    y: i32,
}


fn main(){
    let mut s = vec![];
    for i in 0..10 {
        s.push(Point{x: i*-1, y:i * 3});
    }
    s.sort_by(|a,b| b.x.cmp(&a.x));
    println!("{:?}", s);

    let (mut a, mut b, mut c) = (1, 2, 3);


    // (a, b, c) = (4, 5, 6);
    a = 4;
    b = 5;
    c = 6;
    println!("{} {} {}", a, b, c);

    let a = vec![1,2,3];
    for i in a.iter().rev() {
        println!("{}", i);
    }

    let a = 3;
    let b = 5;
    let c: f32 = a as f32 / b as f32;
    println!("{}", c);

    let mut points: Vec<Point> = vec![];
    points.push(Point{x: 1, y: 1});
    points.push(Point{x: 2, y: 2});
    points.push(Point{x: 3, y: 3});
    for mut p in &mut points {
        p.x += 1;
        p.y += 1;
    }
    println!("{}, {}", points[0].x, points[0].y);
}
