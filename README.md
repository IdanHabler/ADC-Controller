# תכנון ADC בעל 16 ערוצים על FPGA
עידן הבלר - 324140623 </br>
שגיא שיוביץ - 325212744 </br>
מנחה: מאיר אלון </br>
מיקום ביצוע הפרויקט: מעבדת הפרויקטים, אוניברסיטת ת"א </br>

## פרק א' - תרשים הבלוקים
תרשים הבלוקים נבנה באמצעות VIVADO ונראה כך:
![Vivado Block Design](https://github.com/user-attachments/assets/dadc7c27-8dec-4b7c-9b8a-edaddce844a9)



בתרשים נראים מספר בלוקים:
- בלוק בשם Zynq7 Processing System - בלוק המגלם בתוכו את מעבד ה-Zynq.
- בלוק בשם AXI Interconnect - אחראי לחבר בין בלוקים נוספים לבין המעבד, כאשר התקשורת ביניהם תעשה באמצעות פרוטוקול AXI.
- בלוק בשם Processor System Reset - אחראי לסנכרון בין השעונים של ה-PS לבין הבלוקים הנוספים המחוברים אליהם וכן סנכון של אותות ה-reset.
- בלוק בשם AXI Quad SPI - בלוק IP של Xilinx אשר מקבל פקודות מה-PS בפרוטוקול AXI ומבצע על פי הן תקשורת SPI.
כמו כן ניתן לראות מספר פינים לכניסות וליציאות. שניים מהם הם פינים קבועים של ה-PS ואנו לא עושים בהם שימוש: FIXED_IO ו-DDR. הפינים בהם אנו משתמשים לצורך התקשורת עם ה-ADC הם:
- פין כניסה בשם ADC_MISO: הפין בו תעבור התעבורה מה-ADC אל בלוק ה-SPI, כלומר slave -> master.
- פין יציאה בשם ADC_CS: הפין בו יעבור אות ה-Chip Select אשר בורר בין ה-slaves השונים המחוברים ומפעיל אותם בהתאם לפקודה. אצלנו יש רק slave אחד ולכן אות זה הוא ביט בודד.
- פין יציאה בשם ADC_SCK: הפין בו יעבור אות השעון אשר מסנכרן בין ה-master ל-slave.
- פין יציאה בשם ADC_MOSI: הפין בו תעבור התעבורה מבלוק ה-SPI אל ה-ADC, כלומר master -> slave.

תרשים הבלוקים הזה עתיד להיצרב על שכבת ה-PL. לשם כך נדרש ליצור hdl wrapper עבור תרשים הבלוקים, כלומר קוד בשפת Verilog אשר בונה את תרשים הבלוקים ומחבר בין הפינים הרלוונטיים. כמו כן יש לציין constraints (.xdc). בקובץ זה נציין מה הם החיבורים הפיזיים אשר מתקשרים לפינים שפורטו לעיל. בפרויקט זה נחבר בין כרטיס ה-PYNQ ל-ADC באמצעות הפינים הסטנדרטיים של Arduino, לכן החלק היחידי שלא יהיה מוטבע כתגובה בקובץ `base.xdc` הוא:
```
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports adc_CS]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports adc_MOSI]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports adc_MISO]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports adc_SCK]
```
קובץ ה-constraints הבסיסי המתאים ללוח PYNQ-Z2 נמצא ב-repository הרשמי של Xilinx[^1]
כעת ניתן להריץ סינתזה ולאחריה מימוש ולבסוף לקבל קובץ bitsream (.bit), הקובץ אותו צורבים על שכבת ה-PL. כל מימוש שדורש שילוב של חומרה ותוכנה בסביבת העבודה של Xilinx מחויב בקובץ hardware handoff (.hwh). קובץ זה נוצר אוטומטית וגם הוא נדרש על מנת לצרוב את הלוגיקה על שכבת ה-PL. שני הקבצים האלו נמצאים בתיקיית bitstream, ועל קוד הפייתון לעבור לתיקייה זו קודם לכן על מנת להתחיל בהליך הצריבה. לבסוף הקבצים המתקבלים הם: `design_1_wrapper.hwh` ו-`design_1_wrapper.bit`
> [!IMPORTANT]
> חשוב ששמות הקבצים יהיו זהים ויימצאו באותה תיקייה. אחרת, בשלב הצריבה תתקבל שגיאה.


## פרק ב' - חיבור כרטיס PYNQ למחשב
חלק זה מבוסס על המדריך הרשמי באתר PYNQ[^2]:


![image](https://github.com/user-attachments/assets/e771022b-075d-471b-9cc8-15ac64f7c110)

### הוראות חיבור
1. יש להזיז את jumper ה-Boot למצב SD.
2. יש להזיז את jumper ה-Power למצב USB.
3. יש להכניס כרטיס SD צרוב עם תמונת PYNQ. את התמונה (iso.) ניתן להוריד מהאתר הרשמי של PYNQ[^3]:
4. יש לחבר באמצעות כבל micro-usb בין הכרטיס לבין המחשב.
> [!NOTE]
> כעת ניתן להדליק את הכרטיס באמצעות המתג. השלב הבא הוא שינוי הגדרות המחשב על מנת שיוכל לתקשר עם הכרטיס:
5. יש להשים כתובת IP סטטית למחשב. מדריך רשמי נמצא באתר PYNQ[^4]:
6. יש לחבר כבל ethernet בין הכרטיס לבין המחשב.
7. יש לגלוש לכתובת: `http://192.9168.2.99`.
8. יש להקיש בשדה שם המשתמש והסיסמה `xilinx`.
לאחר השלבים האלו ניתן לפתוח מחברת jupyter ולהריץ בה קוד.

[^1]: [https://github.com/Xilinx/PYNQ/blob/master/boards/Pynq-Z2/base/vivado/constraints/base.xdc]
[^2]: [https://pynq.readthedocs.io/en/v2.3/getting_started/pynq_z2_setup.html]
[^3]: [https://www.pynq.io/boards.html]
[^4]: [https://pynq.readthedocs.io/en/v2.3/appendix.html#assign-your-computer-a-static-ip]

### חיבור כרטיס ה-PYNQ אל ה-EVAL-AD4115
חלק זה נבנה על המידע הרשום במפרט הלוח הרשמי מבית Analog Devices[^5]
![image](https://github.com/user-attachments/assets/68c726c2-0665-4238-af9c-2fbd50d993a9)


כאמור, אנו נתחבר אל הלוח באמצעות הפינים הסטנדרטיים של הארדואינו. לשם כך יש לאפשר זאת באמצעות חיבור ה-jumpers הקרויים LK4 - LK6 למצב חיבור סטנדרטי:

![image](https://github.com/user-attachments/assets/ac4d2b4d-bc51-448e-84de-69deb70fb531)


כמו כן, יש לחבר את ה-jumpers בחיבור J6 כך שהאותות שיוזנו הלאה ל-ADC יגיעו מהפינים הסטנדרטיים של הארדואינו ב-J9:

![image](https://github.com/user-attachments/assets/070dcecb-c3c8-4dad-bfea-1e6e0f9fa067)

![image](https://github.com/user-attachments/assets/eea4883d-d438-41ae-b70b-bf5a3c6a8e00)


כמו כן, כיוון שאנו משתמשים בספק כוח חיצוני, יש לחבר את LK3 במצב A, כך שיחובר ל-J4:

![image](https://github.com/user-attachments/assets/6f268f3d-b295-481f-841f-75de19d3f81e)




[^5]: [https://www.analog.com/media/en/technical-documentation/user-guides/eval-ad4115sdz-ug-1820.pdf]
## פרק ג' - ספריית הפייתון
כאמור, לאחר שסיימנו את מלאכת החיבור הפיזי והאלקטרוני בין הכרטיס והמחשב, ניתן להריץ קוד על הכרטיס בסביבת jupyter. הספרייה מורכבת משני חלקים מרכזיים:
> [!WARNING]
> שימוש לא נכון בפונקציות עלול להוביל להתנהגות לא צפויה.
### חלק ראשון - תשתית התקשורת
על מנת לבסס את תשתית התקשורת בין הכרטיב לבין ה-ADC יש ראשית לצרוב את ה-bitstream על שכבת ה-PL. לשם כך נשתמש בספריית `pynq`. בתוך הספרייה קיימת מחלקת `Overlay`, בה נשתמש באופן הבא:
```python
from pynq import Overlay
ol = Overlay("design_1_wrapper.bit")
spi = ol.axi_quad_spi_32_bit
```
> [!CAUTION]
> בצריבת ה-bitstream יש לוודא כי מימוש הפרויקט ב-VIVADO הושלם ללא שגיאות וללא אזהרות קריטיות. צריבה של bitstream שכזה עלולה לפגום ב-FPGA.

בשורה הראשונה מייבאים את המחלקה הרלוונטית מתוך ספריית `pynq`. לאחר מכן אנו יוצרים אובייקט `Overlay` וצורבים את ה-bitstream על ה-PL. לאחר מכן, משתמשים באובייקט זה על מנת לשמור את בלוק ה-SPI באובייקט משלו, כך ניתן לגשת למפת הרגיסטרים שלו ולעשות בו שימוש, כפי שנראה מיד.
שתי הפונקציות המרכזיות הנוגעות לתקשורת בין המשתמש לבין ה-ADC הן `()spi_init` ו-`()spi_transfer`. שתי הפונקציות מתבססות על מפת הרגיסטרים המופיעה בתיעוד הרשמי של בלוק ה-IP באתר Xilinx[^6]:
[^6]: [https://docs.amd.com/r/en-US/pg153-axi-quad-spi]
```python
def spi_init(spi, phase=0, polarity=0):
    spi.write(0x40, 0x0a) # Write the only value allowed to the SRR (Software Reset Register) to reset the core for four AXI clock cycles
    spi.write(0x28, 0x04) # Disable interrupt that says data transmit FIFO is empty
    spi.write(0x1c, 0) # Disable global interrupt (disable all interrupts)
    spi.write(0x70, 0xFFFFFFFF) # Set slave select to all 1's, meaning no slave is selected
    ctrlreg = spi.read(0x60) # Read control register
    ctrlreg = ctrlreg | 0xe6
    """
    Set SPE (SPI system enable) to 1, making the module active
    Set Master to 1, enabling the module to behave as an SPI master
    Set TX FIFO Reset to 1, to reset the transmit FIFO
    Set RX FIFO Reset to 1, to reset the recieve FIFO
    Set Manual Slave Select to 1, enabling us to control the SS output using the SS register
    """
    spi.write(0x60, ctrlreg) # Writing the controls to the control register
    ctrlreg = spi.read(0x60) # Read control register
    ctrlreg = ctrlreg & ~(0x18) 
    """
    Set CPOL to 0, setting the clock as rising edge and not falling edge.
    Set CPHA to 0, setting the valid rising edge as the first.
    """
    # Options to change the properties mentioned above.
    if phase == 1:
        ctrlreg = ctrlreg | 0x10
    if polarity == 1:
        ctrlreg = ctrlreg | 0x08
    spi.write(0x60, ctrlreg)
```
הפונקצייה עורכת את ערכי הרגיסטרים באמצעות הפונקצייה `()spi.write` אשר מקבלת את כתובת הרגיסטר ואת המידע שנרצה לרשום בה. האופציות הרלוונטיות פה, כפי שניתן לראות בתיעוד בתוך הקוד הן קוטביות השעון, כאשר האופציות הן active high - ב-idle השעון ב-0 לוגי, ודגימות נעשות עם עליית השעון. האופציה active low היא כמובן ההפוכה. ניתן גם לשלוט בפאזת השעון.
> [!IMPORTANT]
יש להריץ את הפונקציה בתחילת הקוד ואין לעשות שימוש בפונקצייה `()spi_transfer` לפני הרצת הפונקצייה.

לאחר שביצענו אתחול לבלוק ה-SPI, ניתן לשלוח מידע באמצעות הפונקצייה `()spi_transfer`, אשר מקבלת את אובייקט ה-SPI וכן רשימה של פקטות לשליחה:
```python
def spi_transfer(packet, spi):
    for data in packet:
        spi.write(0x68, data) # Write the specified data to the data transmit FIFO
        spi.write(0x70, 0xFFFFFFFE) # Activate the slave by setting the slave select register to output 1 to slave 0
        
        statReg = spi.read(0x64) # Read the status register *right after writing to TX FIFO*
        
        ctrlreg = spi.read(0x60) # Read the control register
        ctrlreg = ctrlreg & ~(0x100) # Set the Master Transaction Inhibit to 0, making the module start communicating
        spi.write(0x60, ctrlreg) # Write the control register
        
        statReg = spi.read(0x64) # Read the status register *after starting to communicate*
        
        while (statReg & 0x04) == 0: # Wait until the transmit FIFO is empty (the master has sent all the data)
            statReg = spi.read(0x64)
            
        ctrlreg = spi.read(0x60) # Read the control register
        ctrlreg = ctrlreg | 0x100 # Set the Master Transaction Inhibit to 1, making the module stop communicating.
        spi.write(0x60, ctrlreg) # Write the control register
        
    spi.write(0x70, 0xFFFFFFFF) # Disable all slaves
    recvData = []
    RxFifoStatus = spi.read(0x64) & 0x01 # Check if Rx is empty
    while RxFifoStatus == 0: # While the Rx FIFO is not empty
        temp = spi.read(0x6c) # Read the data recieve register
        recvData.append(bin(temp)) # Add the read data to the list
        RxFifoStatus = spi.read(0x64) & 0x01 # Get the Rx FIFO status
    return recvData # return the recieved data
```
כאשר שוב, המימוש נבנה על סמך הידע הרשום במפרט הרשמי.

> ### חלק שני - הרכבת הפקודות
בספרייה מספר פעולות אשר מרכיבות את הביטים שיש לשלוח ל-ADC דרך ממש ה-SPI על מנת לגרום לו לבצע פעולה מסוימת, והן מחולקות לפי סוג הפקודה ועל איזה טווח רגיסטרים היא שולטת. יצירת הפקודות נעשית בצורה אוטומטית, והן מורכבות לפי המפרט הרשמי של ה-ADC באתר Analog Devices[^7].
[^7]: [https://www.analog.com/media/en/technical-documentation/data-sheets/ad4115.pdf]

יש לייבא מספר ספריות נוספות על מנת להשתמש בקוד בחלק זה:
```python
from time import time
from math import *
```
לפי המפרט, כל פקודה מחויבת בכתיבה תחילה לרגיסטר התקשורת `COMMS`, בו נכתבת כתובת הרגיסטר שבה אנו מעוניינים והאם הפעולה היא קריאה או כתיבה. לשם כך קיימת הפונקציה `()start_command`:
```python
def start_command(addr, mode):
    """
    This function recieves a register address and a command mode
    mode = Write/Read
    """
    mode_bit = 1 if mode == "Write" else 0
    return int("0{0}{1:06b}".format(mode_bit, addr))
```

לשם קנפוג רגיסטרי הערוצים קיימת הפונקציה `()configure_channel`:
```python
def configure_channel(channel_num, enable, setup, inputs):
    """
    This function generates the command for the channel configuration registers.
    enable = 0 or 1.
    setup = i in [0, 7].
    inputs = (VIN[i], VIN[j]), where 0 <= i,j <= 15, or COM.
    inputs may also contain TEMP for temperature sensor or REF for reference voltage.
    """
    return [int(start_command(0x10 + channel_num, "Write")), int("{0}{1:03b}0{2}".format(enable, setup, convert_channel_tuple(inputs)))]
```
פונקציה זו מקבלת את מספר הערוץ המבוקש, ביט enable הקובע האם להפעיל את הערוץ או לא, איזה setup להשתמש עבור הערוץ וכן מה הכניסות בהן יעשה שימוש. הפונקציה נעזרת בפעולה הפנימית `()convert_channel_tuple`, אשר מקבל tuple המכיל את שמות שתי הכניסות בהן יעשה שימוש, וממירה אותו למחרוזת הביטים המתאימה:
```python
def convert_channel_tuple(inputs):
    """
    This function converts a tuple of voltage inputs to its corresponding data to be written to the ADC.
    inputs = (VIN[i], VIN[j]), where 0 <= i,j <= 15, or COM.
    inputs may also contain TEMP for temperature sensor or REF for reference voltage.
    """
    if (inputs == ("0", "1")): # (VIN0, VIN1)
        return "0000000001"
    if (inputs == ("0", "com")): # (VIN0, VINCOM)
        return "0000010000"
    if (inputs == ("1", "0")): # (VIN1, VIN0)
        return "0000100000"
    if (inputs == ("1", "COM")): # (VIN1, VINCOM)
        return "0000110000"
    if (inputs == ("2", "3")): # (VIN2, VIN3)
        return "0001000011"
    if (inputs == ("2", "COM")): # (VIN2, VINCOM)
        return "0001010000"
    if (inputs == ("3", "2")): # (VIN3, VIN2)
        return "0001100010"
    if (inputs == ("3", "COM")): # (VIN3, VINCOM)
        return "0001110000"
    if (inputs == ("4", "5")): # (VIN4, VIN5)
        return "0010000101"
    if (inputs == ("4", "COM")): # (VIN4, VINCOM)
        return "0010010000"
    if (inputs == ("5", "4")): # (VIN5, VIN4)
        return "0010100100"
    if (inputs == ("5", "COM")): # (VIN5, VINCOM)
        return "0010110000"
    if (inputs == ("6", "7")): # (VIN6, VIN7)
        return "0011000111"
    if (inputs == ("6", "COM")): # (VIN6, VINCOM)
        return "0011010000"
    if (inputs == ("7", "6")): # (VIN7, VIN6)
        return "0011100110"
    if (inputs == ("7", "COM")): # (VIN7, VINCOM)
        return "0011110000"
    if (inputs == ("8", "9")): # (VIN8, VIN9)
        return "0100001001"
    if (inputs == ("8", "COM")): # (VIN8, VINCOM)
        return "0100010000"
    if (inputs == ("9", "8")): # (VIN9, VIN9)
        return "0100101000"
    if (inputs == ("9", "COM")): # (VIN9, VINCOM)
        return "0100110000"
    if (inputs == ("10", "11")): # (VIN10, VIN11)
        return "0101001011"
    if (inputs == ("10", "COM")): # (VIN10, VINCOM)
        return "0101010000"
    if (inputs == ("11", "10")): # (VIN11, VIN10)
        return "0101101010"
    if (inputs == ("11", "COM")): # (VIN11, VINCOM)
        return "0101110000"
    if (inputs == ("12", "13")): # (VIN12, VIN13)
        return "0110001101"
    if (inputs == ("12", "COM")): # (VIN12, VINCOM)
        return "0110010000"
    if (inputs == ("13", "12")): # (VIN13, VIN12)
        return "0110101100"
    if (inputs == ("13", "COM")): # (VIN13, VINCOM)
        return "0110110000"
    if (inputs == ("14", "15")): # (VIN14, VIN15)
        return "0111001111"
    if (inputs == ("14", "COM")): # (VIN14, VINCOM)
        return "0111010000"
    if (inputs == ("15", "14")): # (VIN15, VIN14)
        return "0111101110"
    if (inputs == ("15", "COM")): # (VIN15, VINCOM)
        return "0111110000"
    if ("TEMP" in inputs): # Temperatur sensor
        return "1000110010"
    if ("REF" in inputs): # Reference voltage
        return "1010110110"
```
בעבור קנפוג רגיסטרי ה-setup, יש את הפונקציה `()configure_setup`:
```python
def configure_setup(setup_num, polarity, ref_buffers, input_buffers, ref_select):
    """
    This function generates the command for the setup configuration registers.
    polarity = Uniploar or Bipolar.
    ref_buffers = (i, j), where i,j in [0, 1]
    input_buffers = 0 or 1.
    ref_select = External, Internal or AV (for AVDD - AVSS)
    """
    polarity_bit = 1 if polarity == "Bipolar" else 0
    ref_buffers_bits = ''.join(ref_buffers)
    input_buffers_bits = str(input_buffers) * 2
    if (ref_select == "External"):
        ref_select_bits = "00"
    elif (ref_select == "Internal"):
        ref_select_bits = "10"
    else:
        ref_select_bits = "11"
    return [int(start_command(0x20 + setup_num, "Write")), int("000{0}{1}{2}00{3}0000".format(polarity_bit, ref_buffers_bits, input_buffers_bits, ref_select_bits), 2)]
```
פונקציה זו מקבלת את מספר ה-setup, את הקוטביות שלו (כלומר האם המתח הנמדד הוא חיובי בלבד או גם חיובי וגם שלילי), האם להשתמש בחוצצים עבור הכניסה, וכן באילו חוצצים להשתמש עבור היציאה.

על מנת לקנפג את רגיסטרי המסננים, נשתמש בפונקציה `()configure_filters`:
```python
def configure_filters(setup_num, filter, post_filter_en, post_filter_opts):
    
    if post_filter_opts == "27 SPS, 47dB rejection, 36.7ms settling":
        post_filter_bits = "010"
    elif post_filter_opts == "25 SPS, 62dB rejection, 40ms settling":
        post_filter_bits = "011"
    elif post_filter_opts == "20 SPS, 86dB rejection, 50ms settling":
        post_filter_bits = "101"
    else:
        post_filter_bits = "110"
    return [int(start_command(0x28 + setup_num, "Write")), int("0000{0}{1}0{2}00000".format(post_filter_en, post_filter_bits, str(filter) * 2))]
```
פונקציה זו מקבלת את מספר ה-setup, באיזה פילטר להשתמש (Sinc3 או Sinc5 & Sinc1, את עקומות ההגבר שלהם ופרטים נוספים אודות המסננים ניתן למצוא במפרט הרשמי של Analog Devices[^5]. כמו כן, היא מאפשרת להפעיל סינון משופר של רעש חשמלי בתדר [Hz]50 ו-[Hz]60 בקנפוגים שונים.

בכדי לבחור את מצב פעולת ה-ADC, יש להשתמש בפונקציה `()configure_mode`:
```python
def configure_mode(sing_cyc, delay, mode, clock_select):
    num = int(delay[:-2])
    if num == 0:
        delay_bits = "000"
    elif num == 8:
        delay_bits = "001"
    elif num == 32:
        delay_bits = "010"
    elif num == 80:
        delay_bits = "011"
    elif num == 200:
        delay_bits = "100"
    elif num == 400:
        delay_bits = "101"
    elif num == 1:
        delay_bits = "110"
    else:
        delay_bits = "111"
    
    if mode == "Continous Conversion":
        mode_bits = "000"
    elif mode == "Single Converstion":
        mode_bits = "001"
    elif mode == "Standby":
        mode_bits = "010"
    elif mode == "Power-down":
        mode_bits = "011"
    elif mode == "Internal Offset Calibration":
        mode_bits = "100"
    elif mode == "Internal Gain Calibratiom":
        mode_bits = "101"
    elif mode == "System Offset Calibration":
        mode_bits = "110"
    else:
        mode_bits = "111"
    
    if clock_select == "Internal Oscillator":
        clk_bits = "00"
    elif clock_select == "Internal Oscillator Output on XTAL2/CLKIO Pin":
        clk_bits = "01"
    elif clock_select == "External Clock Input on XTAL2/CLKIO Pin":
        clk_bits = "10"
    else:
        clk_bits = "11"
    return [int(start_command(0x01 , "Write")), int("00{0}00{1}0{2}{3}00".format(sing_cyc, delay_bits, mode_bits, clk_bits))]
```
הפונקציה מקבלת את האופציה האם להעלות את מוצא ה-ADC רק לאחר שתוצאתו התייצבה במחזור אחד או להעלות אותו באופן הדרגתי על פני כמה מחזורים, האם להוסיף השהייה מלאכותית לפני שמוצא ה-ADC נשלח הלאה, לאיזה מצב פעולה לקנפג את ה-ADC ולבחור את מקור השעון.

הפונקצייה האחרונה עליה נדבר בחלק זה היא פונקציית `()measure`. פונקצייה זו מתחילה מדידה על ידי קריאת מידע מהרגיסטר הרלוונטי למשך 5 שניות ומציגה את המידע המתקבל על מערכת צירים:
```python
def measure(spi, axes_tab):
    start = time()
    curr = time()
    x_data = []
    y_data = []
    while (curr - start) <= 5: # Measure for 5 seconds
        x_data.append(curr - start)
        y_data.append(spi_transfer(start_command(0x04, "Read"), spi))
    
    # Create Figure and plot data
    fig = Figure(figsize=(5, 5), dpi = 100)
    plt = fig.add_subplot(111)
    plt.grid(which='both')
    plt.plot(x_data, y_data)
    plt.set_ylim((-5, 5))
    plt.set_xlim((0, 5))
    plt.set_xlabel("Time[sec]")
    plt.set_ylabel("V[V]")
    plt.set_title("Voltage Waveform")
    canvas = FigureCanvasTkAgg(fig, master = axes_tab)   
    canvas.draw()
    
    # placing the canvas on the Tkinter window 
    canvas.get_tk_widget().pack() 
  
    # creating the Matplotlib toolbar 
    toolbar = NavigationToolbar2Tk(canvas, axes_tab) 
    toolbar.update() 
  
    # placing the toolbar on the Tkinter window 
    canvas.get_tk_widget().pack()
```
> [!NOTE]
> בפונקצייה זו ובפעולת הבקר באופן כללי הונח כי AVDD = 5[V]

### חלק שלישי - ממשק המשתמש
ממשק המשתמש הגרפי (GUI) הורכב באמצעות ספריית `tkinter` ו`matplotlib`. הוא נבנה באמצעות תוכנית מרכזית ובה חלונות לכל סוג פקודה עם הפרמטרים המתאימים לה. הבקר כולו רץ מתוך פונקציית `()app`, אשר לה אנו קוראים ב-`main`. הפונקציה מתחילה באתחול של ה-FPGA כפי שהוסבר לעיל. יש לייבא עבור הפונקציות בחלק זה כמה ספריות:
```python
from tkinter import *
from tkinter import ttk
from matplotlib.figure import Figure
from matplotlib.backends.backend_tkagg import (FigureCanvasTkAgg, NavigationToolbar2Tk)
```
כעת נתאר את הפונקציות:
```python
def app():

    # Set up FPGA Design
    ol = Overlay("design_1_wrapper.bit")
    spi = ol.axi_quad_spi_32_bit
    spi_init(spi, polarity=1)
```
לאחר מכן בונה הפונקצייה את החלון המרכזי של התוכנית:
```python
# Set up GUI
    window = Tk()
    window.title("AD4115 Controller")
    window.geometry("600x600")
```
כעת היא בונה את כל תתי החלונות לכל סוג פקודה:
```python
# Set up tabs
    tabControl = ttk.Notebook(window)
    cc_tab = ttk.Frame(tabControl) # Channel Configuration
    sc_tab = ttk.Frame(tabControl) # Setup Configuration
    fc_tab = ttk.Frame(tabControl) # Filter Configuration
    adcm_tab = ttk.Frame(tabControl) # ADC Mode Configuration
    axes_tab = ttk.Frame(tabControl) # Voltage Waveform Viewer

    tabControl.add(cc_tab, text="Channel Configuration")
    tabControl.add(sc_tab, text="Setup Configuration")
    tabControl.add(fc_tab, text="Filter Configuration")
    tabControl.add(adcm_tab, text="ADC Mode Configuration")
    tabControl.add(axes_tab, text="Voltage Waveform")
    tabControl.pack(expand=1, fill="both")
```
לבסוף מתחילה התוכנית להרכיב את כל תתי החלונות, תחילה על ידי יצירת ה-`widgets` המתאימים מספריית `tkinter` ולאחר מכן ממקמת אותם על החלון שלהם.
תחילה נבנה חלון קנפוג הערוצים:
```python
#### Channel Configuration Widgets
    cc_channel_label = Label(cc_tab, text = "Channel #:")
    cc_channel_box = ttk.Combobox(cc_tab, values = ["{0}".format(i) for i in range(0, 16)])
    cc_channel_box.set("0")
    cc_enable = IntVar()
    cc_enable_cbutton = Checkbutton(cc_tab, text="Enable", variable = cc_enable)
    cc_setup_label = Label(cc_tab, text="Choose Setup:")
    cc_setup_box = ttk.Combobox(cc_tab, values = [str(i) for i in range(0, 8)])
    cc_setup_box.set("0")
    cc_voltage_mode_label = Label(cc_tab, text = "Choose Voltage Mode:")
    cc_voltage_mode = IntVar()
    cc_se_radio = Radiobutton(cc_tab, text="Single Ended", variable=cc_voltage_mode, value=0, command=lambda: update_cc_label(cc_voltage_mode, cc_v_box, cc_v_label))
    cc_diff_radio = Radiobutton(cc_tab, text="Differential", variable=cc_voltage_mode, value=1, command=lambda: update_cc_label(cc_voltage_mode, cc_v_box, cc_v_label))
    cc_input_label = Label(cc_tab, text = "Choose Input for V+:")
    cc_v_box = ttk.Combobox(cc_tab, values = ["V{0}".format(i) for i in range(0, 16)])
    cc_v_box.set("V0")
    cc_v_box.bind("<<ComboboxSelected>>", lambda event: update_cc_label(cc_voltage_mode, cc_v_box, cc_v_label))
    cc_v_label = Label(cc_tab, text = "")
    cc_cmd_button = Button(cc_tab, text="Send Command", activebackground="blue", activeforeground="White", command= lambda: spi_transfer(configure_channel(int(cc_channel_box.get()), int(cc_enable.get()), int(cc_setup_box.get()), (str(cc_v_box.get())[1:], cc_v_label["text"].split(" ")[-1][1:])), spi))
    

    cc_channel_label.grid(row = 0, column = 0, sticky = W, pady = 2)
    cc_channel_box.grid(row = 0, column = 1, sticky = W, pady = 2)
    cc_enable_cbutton.grid(row = 0, column = 2, sticky = W, pady = 2, padx = 10)
    cc_setup_label.grid(row = 1, column = 0, sticky = W, pady = 5)
    cc_setup_box.grid(row = 1, column = 1, sticky = W, pady = 5)
    cc_voltage_mode_label.grid(row = 3, column = 0, sticky = W, pady = 5)
    cc_se_radio.grid(row = 2, column = 1, sticky = W, pady = 5)
    cc_diff_radio.grid(row = 4, column = 1, sticky = W, pady = 5)
    cc_input_label.grid(row = 5, column = 0, sticky = W, pady = 5)
    cc_v_box.grid(row = 5, column = 1, sticky = W, pady = 5)
    cc_v_label.grid(row = 5, column = 2, sticky = W, pady = 5, padx = 10)
    cc_cmd_button.grid(row=6, column=1, sticky = N, pady = 5, columnspan=2)
    ####
```
בחלון זה נעשה שימוש בפונקצייה נוספת, `()update_cc_label`, אשר מעדכנת את התווית המראה מהו המתח השלילי בו נעשה שימוש במצב single ended וגם דיפרנציאלי, זה מכיוון שיש רק זוגות מוגדרים ביניהם אפשר למדוד את המתח. היא מקבלת את widget המצב (single ended או דיפרנציאלי), את widget הכניסה (שבוחר לאיזו כניסה להתייחס בתור המתח החיובי) ואת widget ה-`label` שאותו תעדכן:
```python
def update_cc_label(mode_widget, input_widget, label):
    v_label_text = "V- = V"
    selected_mode = mode_widget.get()
    if selected_mode == 0:
        v_label_text += "COM"
    else:
        selected_Vi = int(str(input_widget.get())[1:])
        if selected_Vi % 2 == 0:
            v_label_text += str(selected_Vi + 1)
        else:
            v_label_text += str(selected_Vi - 1)
    label.config(text = v_label_text)
```

לאחר מכן נבנה חלון קנפוג ה-setup:
```python
#### Setup Configuration Widgets
    sc_setup_label = Label(sc_tab, text = "Setup #:")
    sc_setup_box = ttk.Combobox(sc_tab, values = ["{0}".format(i) for i in range(0, 7)])
    sc_setup_box.set("0")
    sc_polarity = IntVar()
    sc_polarity_label = Label(sc_tab, text="Polarity:")
    sc_uni_radio = Radiobutton(sc_tab, text="Uniploar", variable=cc_voltage_mode, value=0)
    sc_bi_radio = Radiobutton(sc_tab, text="Bipolar", variable=cc_voltage_mode, value=1)
    sc_refp_buf_label = Label(sc_tab, text="REF+ Buffer: ")
    sc_refp_buf = IntVar()
    sc_refp_enable_cbutton = Checkbutton(sc_tab, text="Enable", variable = sc_refp_buf)
    sc_refn_buf_label = Label(sc_tab, text="REF- Buffer: ")
    sc_refn_buf = IntVar()
    sc_refn_enable_cbutton = Checkbutton(sc_tab, text="Enable", variable = sc_refn_buf)
    sc_in_buf = IntVar()
    sc_in_buf_label = Label(sc_tab, text="Input Buffers:")
    sc_in_buf_cbutton = Checkbutton(sc_tab, text = "Enable", variable=sc_in_buf)
    sc_ref_sel_label = Label(sc_tab, text = "Reference Select:")
    sc_ref_sel_box = ttk.Combobox(sc_tab, values = ["External Reference", "Internal 2.5[V] Reference", "AVDD - AVSS"])
    sc_ref_sel_box.set("External Reference")
    sc_cmd_button = Button(sc_tab, text="Send Command", activebackground="blue", activeforeground="White", command=lambda: spi_transfer(configure_setup(int(sc_setup_box.get()), int(sc_polarity.get()), (str(sc_refp_buf.get()), str(sc_refn_buf.get())), int(sc_in_buf.get()), sc_strings_to_val(sc_ref_sel_box.get())), spi))


    sc_setup_label.grid(row=0, column = 0, pady=2)
    sc_setup_box.grid(row=0, column=1, pady=2, padx=10)
    sc_polarity_label.grid(row = 2, column = 0, pady=5)
    sc_uni_radio.grid(row = 1, column = 1, pady = 5)
    sc_bi_radio.grid(row = 3, column = 1, pady=5)
    sc_refp_buf_label.grid(row=4, column=0, pady=5)
    sc_refp_enable_cbutton.grid(row=4, column=1, pady=5, padx=10)
    sc_refn_buf_label.grid(row=4, column = 4, pady=5)
    sc_refn_enable_cbutton.grid(row=4, column = 5, pady=5, padx=10)
    sc_in_buf_label.grid(row=5, column = 0, pady=5)
    sc_in_buf_cbutton.grid(row=5, column = 1, pady=5, padx=10)
    sc_ref_sel_label.grid(row=6, column = 0, pady = 5)
    sc_ref_sel_box.grid(row = 6, column = 1, pady = 5, padx = 10)
    sc_cmd_button.grid(row=7, column=1, pady = 5, columnspan=2)
    ####
```
בחלון זה נעשה שימוש בפונקצייה `()sc_strings_to_val` אשר מקבלת מחרוזת מ-widget החוצצים וממירה אותה למחרוזת הנכונה אשר תיכנס לבדיקה בפונקצייה `()configure_setup` אשר תוארה קודם לכן:
```python
def sc_strings_to_val(str):
    if str == "External Reference":
        return "External"
    if str == "Internal 2.5[V] Reference":
        return "Internal"
    return "AV"
```

אחריו נוצר חלון קנפוג המסננים:
```python
#### Filter Configuration Widgets
    fc_setup_label = Label(fc_tab, text = "Setup #:")
    fc_setup_box = ttk.Combobox(fc_tab, values = ["{0}".format(i) for i in range(0, 7)])
    fc_setup_box.set("0")
    fc_filter_label = Label(fc_tab, text="Filter:")
    fc_filter = IntVar()
    fc_sinc51_radio = Radiobutton(fc_tab, text="Sinc5 & Sinc1", value = 0, variable = fc_filter)
    fc_sinc3_radio = Radiobutton(fc_tab, text = "Sinc3", value = 1, variable=fc_filter)
    fc_post_filter_label = Label(fc_tab, text="Enhanced Filter:")
    fc_post_filter = IntVar()
    fc_post_filter_box = ttk.Combobox(fc_tab, values = ["27 SPS, 47dB rejection, 36.7ms settling", "25 SPS, 62dB rejection, 40ms settling", "20 SPS, 86dB rejection, 50ms settling", "16.67 SPS, p2dB rejection, 60ms settling"], width=40)
    fc_post_filter_enable = IntVar()
    fc_post_filter_cbutton = Checkbutton(fc_tab, text="Enable", variable=fc_post_filter_enable, command = lambda: update_fc_widgets(fc_post_filter_enable.get(), fc_post_filter_box))
    fc_cmd_button = Button(fc_tab, text="Send Command", activebackground="blue", activeforeground="White", command=lambda: spi_transfer(configure_filters(int(fc_setup_box.get()), fc_filter.get(), fc_post_filter_enable.get(), fc_post_filter_box.get()), spi))


    fc_setup_label.grid(row=0, column=0, pady=2)
    fc_setup_box.grid(row=0, column=1, pady=2, padx=10)
    fc_filter_label.grid(row=2, column=0, pady=5)
    fc_sinc51_radio.grid(row = 1, column = 1, pady = 5, padx = 10)
    fc_sinc3_radio.grid(row=3, column=1, pady=5, padx=10)
    fc_post_filter_label.grid(row=4, column = 0, pady = 5)
    fc_post_filter_cbutton.grid(row=4, column=1, pady = 5, padx = 10)
    fc_cmd_button.grid(row=5, column=1, pady = 5, columnspan=2)
    ####
```
כאשר בחלון זה נעשה שימוש בפונקצייה `()update_fc_widgets` אשר מקבלת ביט enable המסמן האם משתמשים בסינון משופר נגד רעש חשמלי, ואת widget ה-`Combobox` אשר יברור את סוגו. למעשה, אין צורך להציג את widget זה אם לא נעשה שימוש בסינון המשופר, ופונקציה זו דואגת לעדכן את החלון לפי מצב זה:
```python
def update_fc_widgets(enable, widget):
    if enable:
        widget.grid(row = 3, column = 2, pady = 5, padx = 10)
    else:
        widget.grid_forget()
```

כעת, נבנה החלון המקנפג את מצב ה-ADC:
```python
#### ADC Mode Widgets
    adcm_sing_cyc_label = Label(adcm_tab, text="Single Cycle Output:")
    adcm_sing_cyc = IntVar()
    adcm_sing_cyc_cbutton = Checkbutton(adcm_tab, text="Enable", variable=adcm_sing_cyc)
    adcm_delay_label = Label(adcm_tab, text="Delay:")
    adcm_delay_box = ttk.Combobox(adcm_tab, values = ["0\u03BCs", "8\u03BCs", "32\u03BCs", "80\u03BCs", "200\u03BCs", "400\u03BCs", "1ms", "2ms"])
    adcm_delay_box.set("0\u03BCs")
    adcm_mode_label = Label(adcm_tab, text="Mode:")
    adcm_mode_box = ttk.Combobox(adcm_tab, values=["Continous Conversion", "Single Conversion", "Standby", "Power-down", "Internal Offset Calibration", "Internal Gain Calibratiom", "System Offset Calibration", "System Gain Calibration"])
    adcm_mode_box.set("Continous Conversion")
    adcm_clock_sel_label = Label(adcm_tab, text= "Clock Select:")
    adcm_clock_sel_box = ttk.Combobox(adcm_tab, values = ["Internal Oscillator", "Internal Oscillator Output on XTAL2/CLKIO Pin", "External Clock Input on XTAL2/CLKIO Pin", "External Crystal on XTAL1 Pin & XTAL2/CLKIO Pin"], width = 50)
    adcm_clock_sel_box.set("Internal Oscillator")
    adcm_cmd_button = Button(adcm_tab, text="Send Command", activebackground="blue", activeforeground="White", command = lambda: spi_transfer(configure_mode(adcm_sing_cyc.get(), adcm_delay_box.get(), adcm_mode_box.get(), adcm_clock_sel_box.get()), spi))

    adcm_sing_cyc_label.grid(row=0, column=0, pady=2)
    adcm_sing_cyc_cbutton.grid(row=0, column=1, pady=5, padx=10)
    adcm_delay_label.grid(row=1, column=0, pady=5)
    adcm_delay_box.grid(row=1, column=1, pady=5, padx=10)
    adcm_mode_label.grid(row=2, column=0, pady=5)
    adcm_mode_box.grid(row=2, column=1, pady=5, padx=10)
    adcm_clock_sel_label.grid(row=3, column=0, pady=10)
    adcm_clock_sel_box.grid(row=3, column=1, pady=5, padx=10)
    adcm_cmd_button.grid(row=4, column=1, pady=5, columnspan=2)

    ####
```
לבסוף, נבנה חלון הצגת מדידות המתח:
```python
    #### Voltage Waveform Widgets
    vw_start_meas_button = Button(axes_tab, text="Start Measurement", command= lambda: measure(spi, axes_tab))
    vw_start_meas_button.pack()
    ####
```

כעת, לאחר שבנתה התוכנית את כל החלונות, מריצים את פונקציית ה-`()mainloop` של אובייקט `Tk` וכך מוצג החלון.

![Voltage Waveform Example](https://github.com/user-attachments/assets/808448f3-b821-43cf-8471-997cf1622240)


> [!TIP]
> שימוש מהנה ובהצלחה!
