require './vfl2code.rb'
require 'minitest/autorun'

class VFLTest < Minitest::Test
    def test_basic
        input = "|[b1]|"
        output = "CGRect f0;f0=b1.frame;f0.origin.x=0;f0.size.width=superview.bounds.size.width-(0)-f0.origin.x;b1.frame=f0;b1.autoresizingMask|=UIViewAutoresizingFlexibleWidth;[superview addSubview:b1];"
        assert transform_raw_code(input, false, 0).include? output
    end


    def test_predefined_size
        input = "V:|-x-[itemA(w)]-x2-[itemB]-x3-[itemC(>0)]|"
        output = "CGRect f0;f0=itemA.frame;f0.origin.y=0+x;f0.size.height=w;itemA.frame=f0;itemA.autoresizingMask|=UIViewAutoresizingFlexibleBottomMargin;[superview addSubview:itemA];f0=itemB.frame;f0.origin.y=0+x+w+x2;itemB.frame=f0;itemB.autoresizingMask|=UIViewAutoresizingFlexibleBottomMargin;[superview addSubview:itemB];f0=itemC.frame;f0.origin.y=CGRectGetMaxY(itemB.frame)+0+x3;f0.size.height=superview.bounds.size.height-(0)-f0.origin.y;itemC.frame=f0;itemC.autoresizingMask|=UIViewAutoresizingFlexibleHeight;[superview addSubview:itemC];"

        assert transform_raw_code(input, false, 0).include? output
    end


    def test_incomplete
        input = "[d(40)]"
        output = "CGRect f0;f0=d.frame;f0.size.width=40;d.frame=f0;[superview addSubview:d];"
        assert transform_raw_code(input, false, 0).include? output
    end

    def test_swift
      input = "center[e(50)]\nV:[e(50)]-30-|"
      output = "var f0:CGRect;f0=e.frame;f0.size.width=50;f0.origin.x=(superview.bounds.size.width-f0.size.width)/2.0;f0.origin.y=superview.bounds.size.height-(0+30)-50;f0.size.height=50;e.frame=f0;e.autoresizingMask|=UIViewAutoresizing.FlexibleLeftMargin|UIViewAutoresizing.FlexibleRightMargin;e.autoresizingMask|=UIViewAutoresizing.FlexibleTopMargin;superview.addSubview(e);"
      assert transform_raw_code(input, true, 0).include? output
    end

    def test_dependence
        input = "|-x1-[A][B][C(>0)][D][E][F]-x2-|"
        output = "var f0:CGRect;f0=A.frame;f0.origin.x=0+x1;A.frame=f0;A.autoresizingMask|=UIViewAutoresizing.FlexibleRightMargin;superview.addSubview(A);f0=B.frame;f0.origin.x=CGRectGetMaxX(A.frame)+0;B.frame=f0;B.autoresizingMask|=UIViewAutoresizing.FlexibleRightMargin;superview.addSubview(B);f0=F.frame;f0.origin.x=superview.bounds.size.width-(0+x2)-f0.size.width;F.frame=f0;F.autoresizingMask|=UIViewAutoresizing.FlexibleLeftMargin;superview.addSubview(F);f0=E.frame;f0.origin.x=CGRectGetMinX(F.frame)-(0)-f0.size.width;E.frame=f0;E.autoresizingMask|=UIViewAutoresizing.FlexibleLeftMargin;superview.addSubview(E);f0=D.frame;f0.origin.x=CGRectGetMinX(E.frame)-(0)-f0.size.width;D.frame=f0;D.autoresizingMask|=UIViewAutoresizing.FlexibleLeftMargin;superview.addSubview(D);f0=C.frame;f0.origin.x=CGRectGetMaxX(B.frame)+0;f0.size.width=CGRectGetMinX(D.frame)-(0)-f0.origin.x;C.frame=f0;C.autoresizingMask|=UIViewAutoresizing.FlexibleWidth;superview.addSubview(C);"

        assert transform_raw_code(input, true, 0).include? output
    end
end
