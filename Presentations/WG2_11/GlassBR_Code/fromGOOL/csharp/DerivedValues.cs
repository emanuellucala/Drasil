using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;

namespace GlassBR {
    public class DerivedValues {
        
        public static void derived_params(InputParameters inparams) {
            inparams.asprat = inparams.a / inparams.b;
            inparams.sd = Math.Sqrt(((Math.Pow(inparams.sdx, 2.0)) + (Math.Pow(inparams.sdy, 2.0))) + (Math.Pow(inparams.sdz, 2.0)));
            inparams.ldf = Math.Pow(inparams.td / 60.0, inparams.m / 16.0);
            inparams.wtnt = inparams.w * inparams.tnt;
            if (inparams.t == 2.5) {
                inparams.h = 2.16;
            }
            else if (inparams.t == 2.7) {
                inparams.h = 2.59;
            }
            else if (inparams.t == 3.0) {
                inparams.h = 2.92;
            }
            else if (inparams.t == 4.0) {
                inparams.h = 3.78;
            }
            else if (inparams.t == 5.0) {
                inparams.h = 4.57;
            }
            else if (inparams.t == 6.0) {
                inparams.h = 5.56;
            }
            else if (inparams.t == 8.0) {
                inparams.h = 7.42;
            }
            else if (inparams.t == 10.0) {
                inparams.h = 9.02;
            }
            else if (inparams.t == 12.0) {
                inparams.h = 11.91;
            }
            else if (inparams.t == 16.0) {
                inparams.h = 15.09;
            }
            else if (inparams.t == 19.0) {
                inparams.h = 18.26;
            }
            else if (inparams.t == 22.0) {
                inparams.h = 21.44;
            }
            if (inparams.gt == 1) {
                inparams.gtf = 1.0;
            }
            else if (inparams.gt == 2) {
                inparams.gtf = 2.0;
            }
            else if (inparams.gt == 3) {
                inparams.gtf = 4.0;
            }
        }
    }
}

