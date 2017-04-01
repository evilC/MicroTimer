using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TestApp
{
    class Program
    {
        static void Main(string[] args)
        {
            var handler1 = new Action(() => { Console.WriteLine("HERE"); });

            var mt = new MicroTimer();
            var timer = mt.CreateMicro(handler1, 500);
            timer.Start();

        }
    }
}
