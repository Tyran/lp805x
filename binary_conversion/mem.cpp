#include <string>
#include <string.h>
#include <sstream>
#include <iostream>
#include <fstream>

#define uint unsigned int

#define ROM4x1ADDR(a) (((a)&0xFFFC)>>2)

using namespace std;

template <class T>
bool from_string(T& t, 
                 const std::string& s,
                 std::ios_base& (*f)(std::ios_base&))
{
  std::istringstream iss(s);
  return !(iss >> f >> t).fail();
}

int main( int argc, char ** argv)
{
    ofstream rom0,rom1,rom2,rom3,ea;
    ifstream in;
    
    if ( argc != 4)
    {
        cout << "Run as mem.exe [TypeOutput] [inputFile] [outputPath]" << endl;
        return -2;
    }
    in.open( argv[2]);
    
    string path(argv[3]);
    string rom[] = { "rom0.mif", "rom1.mif", "rom2.mif", "rom3.mif" };
	string romx[] = { "oc8051rom.mif", "oc8051romb.mif" };
	string romc[] = { "oc8051rom0.coe", "oc8051rom1.coe" };
    
	if ( strcmp(argv[1],"-MIF") == 0)
	{
		for ( int i=0; i<4; i++)
		{
			rom[i] = path + rom[i];
		}
    
    rom0.open(rom[0].c_str());
    rom1.open(rom[1].c_str());
    rom2.open(rom[2].c_str());
    rom3.open(rom[3].c_str());
	}
	else if ( strcmp(argv[1],"-IN") == 0)
	{
		string file=path+"oc8051_rom.in";
		ea.open(file.c_str());
	}
	
	else if ( strcmp(argv[1],"-XMIF") == 0)
	{
		for ( int i=0; i<2; i++)
		{
			romx[i] = path + romx[i];
		}
	
	rom0.open(romx[0].c_str());
    rom1.open(romx[1].c_str());
	}
	
	else if ( strcmp(argv[1],"-COE") == 0)
	{
		for ( int i=0; i<2; i++)
		{
			romc[i] = path + romc[i];
		}
		
	rom0.open(romc[0].c_str());
    rom1.open(romc[1].c_str());
	}
	
	else
	{
		cout << "Unknown type conversion!" << endl;
		return -1;
	}
	
    string line;
    uint lineN=0;
    
    string ini = "WIDTH=8;\nDEPTH=16384;\n\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\nCONTENT BEGIN\n";
    string fini = "END;";
	
	string cini = "memory_initialization_radix=16;\nmemory_initialization_vector=\n";
	string cfini = ";";

	if ( strcmp(argv[1],"-MIF") == 0)
	{
		rom0 << ini;
		rom1 << ini;
		rom2 << ini;
		rom3 << ini;
	}
	
	else if ( strcmp(argv[1],"-XMIF") == 0)
	{
		//rom0 << ini;
		//rom1 << ini;
	}
	
	else if ( strcmp(argv[1],"-COE") == 0)
	{
		rom0 << cini;
		rom1 << cini;
	}

    if (in.is_open())
    {
	bool xcoei=true;
	bool xcoeii=true;
	
        while ( in.good())
        {
          getline (in,line);
          
          if ( line[0] != ':')
          {
            //cout << "Missing `:` at line " << lineN << endl;
            continue;
          }
          
          uint count=0;
          
          if(from_string<uint>(count, line.substr(1,2), std::hex))
          {
          uint address=0;
          
            if ( count > 0)
            {
            if(from_string<uint>(address, line.substr(3,4), std::hex))
              {
                uint type=0;
                uint i=0;
          
                if(from_string<uint>(type, line.substr(7,2), std::hex))
                  {
                    
                    if ( type == 0x00)
                    {
                    uint count_ = count;
                    uint bcount = address & 0x03;
                    
                        do
                        {
							//cout << line.substr(9+i,2) << endl;
                            //byte to byte
							if ( strcmp(argv[1],"-MIF") == 0)
							{
								switch ( bcount)
								{
									case 0:
										rom0 << hex << ROM4x1ADDR(address) << " : " << line.substr(9+i,2) << ";" << endl;
									break;
									case 1:
										rom1 << hex << ROM4x1ADDR(address) << " : " << line.substr(9+i,2) << ";" << endl;               
									break;
									case 2:
										rom2 << hex << ROM4x1ADDR(address) << " : " << line.substr(9+i,2) << ";" << endl;               
									break;
									case 3:
										rom3 << hex << ROM4x1ADDR(address) << " : " << line.substr(9+i,2) << ";" << endl;               
									break;
									default:
									break;
								}
							}
							else if ( strcmp(argv[1],"-IN") == 0)
							{
								ea << line.substr(9+i,2) << endl;
							}
							
							else if ( strcmp(argv[1],"-XMIF") == 0)
							{
								switch ( bcount)
								{
									case 0:
										rom0 << hex << line.substr(9+i,2) << endl;
									break;
									case 1:
										rom0 << hex << line.substr(9+i,2) << endl;
									break;
									case 2:
										rom1 << hex << line.substr(9+i,2) << endl;
									break;
									case 3:
										rom1 << hex << line.substr(9+i,2) << endl;
									break;
									default:
									break;
								}
							}
							
							else if ( strcmp(argv[1],"-COE") == 0)
							{
								switch ( bcount)
								{
									case 0:
									if ( xcoei==false)
									{
										rom0 << "," << endl;
									}
										rom0 << hex << line.substr(9+i,2);
										xcoei=false;
									break;
									case 1:
									if ( xcoei==false)
									{
										rom0 << "," << endl;
									}
										rom0 << hex << line.substr(9+i,2);
									xcoei=false;
									break;
									case 2:
									if ( xcoeii==false)
									{
										rom1 << "," << endl;
									}
										rom1 << hex << line.substr(9+i,2);
									xcoeii=false;
									break;
									case 3:
									if ( xcoeii==false)
									{
										rom1 << "," << endl;
									}
										rom1 << hex << line.substr(9+i,2);
									xcoeii=false;
									break;
									default:
									break;
								}

							}
                            
                            i+=2;
                            address++;
                            if ( ++bcount == 4)
                            {
                                
                                bcount=0;
                            }
                        
                        
                        //cout << count_ << endl;
                        }
                        while (--count_ != 0);
                    }
                    
                    else { cout << "Don't know what to do here..." << endl; }
                  
                    //cout << hex << type << endl;
                  }
                else
                  {
                    cout << "from_string type failed" << endl;
                  } 
              
                //cout << hex << address << endl;
              }
            else
              {
                cout << "from_string address failed" << endl;
              }       
            }
            //cout << hex << count << endl;
          }
          else
          {
            cout << "from_string count failed" << endl;
          }
          
          //cout << "Line: " << line << endl;
          
          lineN++;
        }
        
	if ( strcmp(argv[1],"-MIF") == 0)
	{
        rom0 << fini;
        rom1 << fini;
        rom2 << fini;
        rom3 << fini;
		
	rom0.close();
    rom1.close();
    rom2.close();
    rom3.close();
    }
	
	else if ( strcmp(argv[1],"-IN") == 0)
	{
	ea.close();
    }
	
	else if ( strcmp(argv[1],"-XMIF") == 0)
	{
	 //       rom0 << fini;
     //   rom1 << fini;
	rom0.close();
    rom1.close();
    }
	else if ( strcmp(argv[1],"-COE") == 0)
	{
	rom0 << cfini;
    rom1 << cfini;
	rom0.close();
    rom1.close();
    }
	
    in.close();
    
    cout << "Conversion Complete!" << endl;
    }
    else 
    {
        cout << "Can't Open File!"; 
    }

    while ( getchar() != '\n') ;

return 0;
}
