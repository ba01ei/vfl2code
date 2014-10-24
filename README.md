# Summary

`vfl2code` is a tool to convert VFL (Visual Formatting Language) based UI layout to native, frame-based, Objective-C or Swift code.

# Table of Contents

1. [Usage](#usage)
2. [Sample Rules](#sample-rules)
3. [A rule of thumb](#a-rule-of-thumb)
4. [Variables and constants](#variables-and-constants)
5. [Frame overriding](#frame-overriding)
6. [Command line tools](#command-line-tools)
7. [Further integration](#further-integration)
8. [License](#license)

# Usage

## 1. One-time setup

```
sudo ./setup.rb
```

## 2. Integrate with your Xcode project

Navigate to your target, click "Build Phases", click "+", add a "New Run Script Phase", drag it to before "Compile Sources".

Inside the script editing field, type

    vfl2code.rb -A ${PROJECT_DIR}

or

    vfl2code.rb -A ${PROJECT_DIR}/some_folder

where some_folder is the folder where you have all your Objective C and Swift code files.

## 3. Create a VFL code block

To start a new VFL based code block, enter something like below in the right place in your code:

    UIView* superview = someView;
    // begin VFL
    /*
        |-10-[someElement]-10-|
        V:|-5-[someElement(100)]
    */
    // end VFL

*Note:* the first line and the last line are important. The final `// end VFL` must be followed by a LF line break (`\n`). You can also `// VFL begin` and `// VFL end`

You can also type vflswift or vflobjc to trigger the code snippet and insert the basic structure.

## 4. Build/Run the project

# Sample Rules

```
|-5-[A(100)]
```
This means that element A is 5 points from the left edge of its container, and it's 100 points wide. And A has flexible right margin.

```
V:|-10-[B(50)]
```
This means that element B is 10 points from the top edge and is 50 points tall. (V means vertical). And B has flexible bottom margin.

```
|-5-[C]-5-|
```
This means that C has flexible width, and it's 5 points to the left edge and 5 points to the right edge.

```
V:[D]|
```
This means that D is touching the bottom edge, and have a flexible top margin, and D's height should be set beyond the VFL based block (either before or after)

```
|-5-[E]-5-[F(50)]-5-[G(>0)]-5-|
```
This means that E has a fixed width set outside the VFL block, F has a fixed width of 50 points, G has a flexible width

```
[H(100)]
```
This means that H is 100 points wide. However **it's position and autoresizing mask is unknown, so you need to set them beyond the VFL block**.

# A rule of thumb

The rule of thumb is that there can be 1 and only 1 flexible element in each dimension:

```
|-5-[A(100)]-5-|
```
This is wrong because when the superview width is not 110 there will be a conflict.

```
|-5-[A(>0)]-5-[B(>0)]-5-|
```
This is wrong because it is an ambiguous layout—it is unclear on how to assign the widths for A and B.

# Variables and constants

Variables and constants can be used to replace the numbers:

```
|-margin-[button(width)]
```

Everything else follows [Apple's official VFL documentation](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/AutolayoutPG/VisualFormatLanguage/VisualFormatLanguage.html), with one exception: `vlf2objc` supports `center` before brackets.

```
center[A(200)]
```
This means A's width is 200 and A is horizontally centered in its superview.

```
V:center[B(100)]
```
This means B's height is 100 and B is vertically centered in its superview.

# Frame overriding

**Unlike** Cocoa Autolayout, `vfl2code` allows you to override the frame of an element before or after the generated code block.

For example this is valid allowed:

    labelA.text = @"hi";
    [labelA sizeToFit];
    // generated code based on |-[labelA]-10-[itemB]

This is also valid and allowed:

    // generated code based on [itemX(100)]
    UpdateWidthBasedOnSomeLogic(itemX); // this keeps the x, y, height set in the VFL block and just updates the width

However, the following example will not work:

    // generated code based on |[itemX]-[itemY(100)]
    [itemX setWidth:100];

`itemY`'s position depends on `itemX`'s frame, so `itemX`'s `setWidth` call must go before the generated code block.


Command line tools
==================

You can use this script to convert raw VFL to Objective-C code from command line:

    echo "|-10-[button]
    V:[button]-|" | vfl2code.rb --raw

Or convert an Objective-C source code file, preserving non-VFL areas. To do so, run either:

    cat yourfile.swift | vfl2code.rb --swift > yourfile_with_changes.swift

Or transform it in place:

    vfl2code.rb -f yourfile.m

Or transform a folder recursively in place:

    vfl2code.rb -A yourfile.m

You can use -a to dry run.


License
=======

Copyright (C) 2013 by Hulu, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
