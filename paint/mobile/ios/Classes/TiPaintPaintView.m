/**
 * Titanium Paint Module
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiPaintPaintView.h"
#import "TiUtils.h"

@implementation TiPaintPaintView

- (id)init
{
	if ((self = [super init]))
	{
		strokeWidth = 5;
        strokeAlpha = 1;
		strokeColor = CGColorRetain([[TiUtils colorValue:@"#000"] _color].CGColor);
        self.multipleTouchEnabled = YES;
	}
	return self;
}

-(BOOL)proxyHasTapListener
{
    // The TiUIView only sets multipleTouchEnabled to YES if we have a tap listener.
    // So... let's make it think that we do! (Note that we don't actually need one.)
	return YES;
}

- (void)dealloc
{
	RELEASE_TO_NIL(drawImage);
	CGColorRelease(strokeColor);
	[super dealloc];
}

- (void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
	[super frameSizeChanged:frame bounds:bounds];
	if (drawImage!=nil)
	{
		[drawImage setFrame:bounds];
	}
    
    // MOD-348: Ensure that we get a solid box in which to draw. Otherwise, we'll end
    // up with blurry lines and visual defects.
    drawBox = CGRectMake(bounds.origin.x, bounds.origin.y,
                            ceilf(bounds.size.width), ceilf(bounds.size.height));
}

- (UIImageView*)imageView
{
	if (drawImage==nil)
	{
		drawImage = [[UIImageView alloc] initWithImage:nil];
		drawImage.frame = [self bounds];
		[self addSubview:drawImage];
	}
	return drawImage;
}

- (void)drawSolidLineFrom:(CGPoint)lastPoint to:(CGPoint)currentPoint
{
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
}

- (void)drawEraserLineFrom:(CGPoint)lastPoint to:(CGPoint)currentPoint
{
    // This is an implementation of Bresenham's line algorithm
    int x0 = currentPoint.x, y0 = currentPoint.y;
    int x1 = lastPoint.x, y1 = lastPoint.y;
    int dx = abs(x0-x1), dy = abs(y0-y1);
    int sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    int err = dx - dy, e2;
    
    while(true)
    {
        CGContextClearRect(UIGraphicsGetCurrentContext(), CGRectMake(x0, y0, strokeWidth, strokeWidth));
        if (x0 == x1 && y0 == y1)
        {
            break;
        }
        e2 = 2 * err;
        if (e2 > -dy)
        {
            err -= dy;
            x0 += sx;
        }
        if (e2 < dx)
        {
            err += dx;
            y0 += sy;
        }
    }
}

- (void)drawFrom:(CGPoint)lastPoint to:(CGPoint)currentPoint
{
	[drawImage.image drawInRect:CGRectMake(0, 0, drawBox.size.width, drawBox.size.height)];
    if (erase) {
        [self drawEraserLineFrom:lastPoint to:currentPoint];
    }
    else {
        [self drawSolidLineFrom:lastPoint to:currentPoint];
    }
}

- (void)drawTouches:(NSSet *)touches
{
    UIGraphicsBeginImageContext(drawBox.size);
    
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth);
    CGContextSetAlpha(UIGraphicsGetCurrentContext(), strokeAlpha);
    CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor);
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    
    for (UITouch* touch in [touches allObjects]) {
        [self drawFrom:[touch previousLocationInView:[self imageView]] to:[touch locationInView:[self imageView]]];
    }
    
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    drawImage.image = UIGraphicsGetImageFromCurrentImageContext();
    
	UIGraphicsEndImageContext();
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesBegan:touches withEvent:event];
	[self drawTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesMoved:touches withEvent:event];
	[self drawTouches:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesEnded:touches withEvent:event];
	[self drawTouches:touches];
}

#pragma mark Public APIs

- (void)setEraseMode_:(id)value
{
	erase = [TiUtils boolValue:value];
}

- (void)setStrokeWidth_:(id)width
{
	strokeWidth = [TiUtils floatValue:width];
}

- (void)setStrokeColor_:(id)value
{
	CGColorRelease(strokeColor);
	TiColor *color = [TiUtils colorValue:value];
	strokeColor = [color _color].CGColor;
	CGColorRetain(strokeColor);
}

- (void)setStrokeAlpha_:(id)alpha
{
    strokeAlpha = [TiUtils floatValue:alpha] / 255.0;
}

- (void)setImage_:(id)value
{
    ENSURE_UI_THREAD(setImage_, value);
    RELEASE_TO_NIL(drawImage);
    UIImage* image = value == nil ? nil : [TiUtils image:value proxy:self.proxy];
    if (image != nil) {
        drawImage = [[UIImageView alloc] initWithImage:image];
        drawImage.frame = [self bounds];
        [self addSubview:drawImage];
        UIView *view = [self imageView];
        [drawImage.image drawInRect:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)];
    }
}

- (void)clear:(id)args
{
	if (drawImage!=nil)
	{
		drawImage.image = nil;
	}
}

@end
