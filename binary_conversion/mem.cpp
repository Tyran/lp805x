#include <string>
#include <string.h>
#include <sstream>
#include <iostream>
#include <fstream>
#include <array>
#include <sstream>

#define uint unsigned int

#define ROM4x1ADDR(a) (((a)&0xFFFC)>>2)

using namespace std;

template<class T>
string toString(const T& t)
{
     ostringstream stream;
     stream << t;
return stream.str();
}

template <class T>
bool from_string(T& t, 
                 const std::string& s,
                 std::ios_base& (*f)(std::ios_base&))
{
  std::istringstream iss(s);
  return !(iss >> f >> t).fail();
}

//simulate rom memory static or self-growing;
//static is non-muttable but faster!
template <typename D, size_t S=1024>
class MemoryModel {
public:
	enum PUSHMODEL { STATIC, SELFGROWING };

private:
//for now only static supported
	array<D,S> _mem;
	PUSHMODEL _model;
	
	bool _sticky;
	
	void m_exchangeEndian( ostringstream & in)
	{
		unsigned int data[4];
		string str = in.str();
		
		for ( int i=0,j=3; i<8; i+=2, j--)
		{
			from_string(data[j],str.substr(i,2),std::hex);
		}
		in.str("");
		
		for ( int i=0; i<4; i++)
		{
			if ( data[i] < 0x10)
				in << "0";
			in << hex << data[i];
		}
	}

public: 
	MemoryModel( PUSHMODEL model) : _model(model) 
	{
		_mem.fill(0);
		_sticky=false;
	}
	~MemoryModel() { }
	
	void insertValue( size_t location, D value)
	{ 
		if ( location > S)
		{
			if ( _sticky == false) 
			{
				_sticky=true;
				cout << "You need a wider ROM..." << endl; 
			}
		}
		else
		{
			_mem[location] = value;
		}
	}
	
	void printCOE8( ofstream & out) 
	{
	typename array<D,S>::iterator it;
	out << "memory_initialization_radix=16;\nmemory_initialization_vector=\n";
		for ( it=_mem.begin(); it<_mem.end(); ++it )
		{
			unsigned int nn=*it;
			if ( nn < 0x10)
				out << "0";
			out << hex << nn << "," << endl;
		}
	out << ";";
	}
	
	void printIN( ofstream & out) 
	{
	ostringstream tmp;
	int cnt=3;
		for ( auto it=_mem.cbegin(); it!=_mem.cend(); ++it, --cnt )
		{
			if ( *it < 0x10)
				tmp << "0";
			tmp << hex << (unsigned int)*it;
			
			if ( cnt == 0)
			{	
				cnt = 4;
				
				m_exchangeEndian(tmp);
				
				out << tmp.str() << endl;
				tmp.str("");
			}
		}
	}
	
	void printCOE( ofstream & out) 
	{
	//typename array<D,S>::iterator it;
	int cnt=3;
	ostringstream tmp;
	out << "memory_initialization_radix=16;\nmemory_initialization_vector=\n";
		for ( auto it=_mem.cbegin(); it!=_mem.cend(); ++it, --cnt )
		{
			if ( it != _mem.begin())
			{
				if ( cnt == 3) 
				{
					out << "," << endl;
				}
			}
			
			if ( *it < 0x10)
				tmp << "0";
			tmp << hex << (unsigned int)*it;
			
			if ( cnt == 0)
			{	
				cnt = 4;
				
				m_exchangeEndian(tmp);
				
				out << tmp.str();
				tmp.str("");
			}
		}
	out << ";";
	}
	
	void printMIF( ofstream & out)
	{
	ostringstream tmp;
	int cnt=3;
	out << "WIDTH=32;\nDEPTH=" << (S/4) << ";\n\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\nCONTENT BEGIN\n" << endl;
		for ( int i=0; i<static_cast<int>(S); ++i, --cnt )
		{
			if ( _mem[i] < 0x10)
				tmp << "0";
			tmp << hex << (unsigned int)_mem[i];
			
			if ( cnt == 0)
			{	
				cnt = 4;
				
				m_exchangeEndian(tmp);
				
				out << hex << (i-3)/4 << "\t:\t";
				out << tmp.str() << ";" << endl;
				tmp.str("");
			}
		}
	out << "END;" << endl;
	}
	
	void printOUT( void) 
	{
	typename array<D,S>::iterator it;
		for ( it=_mem.begin(); it<_mem.end(); ++it )
		{
			cout << *it << endl;
		}
	}
};

int main( int argc, char ** argv)
{
    ofstream rom[4];
    ifstream in;
	MemoryModel<unsigned char,16384> MEM( MemoryModel<unsigned char,16384>::STATIC);
	
    
    if ( argc != 4 && argc != 5)
    {
        cout << "Run as memc.exe TypeOutput inputFile outputPath/File" << endl;
        return -2;
    }
    in.open( argv[2]);
    
    string path(argv[3]);
    string romn[] = { "rom0.mif", "rom1.mif", "rom2.mif", "rom3.mif" };
	string romx[] = { "oc8051rom.mif", "oc8051romb.mif" };
	string romc[] = { "oc8051rom[0].COE32", "oc8051rom[1].COE32" };
    
	if ( strcmp(argv[1],"-MIF") == 0)
	{
		for ( int i=0; i<4; i++)
		{
			romn[i] = path + romn[i];
		}
    
    rom[0].open(romn[0].c_str());
    rom[1].open(romn[1].c_str());
    rom[2].open(romn[2].c_str());
    rom[3].open(romn[3].c_str());
	}
	
	else if ( strcmp(argv[1],"-XMIF") == 0)
	{
		for ( int i=0; i<2; i++)
		{
			romx[i] = path + romx[i];
		}
	
	rom[0].open(romx[0].c_str());
    rom[1].open(romx[1].c_str());
	}
	
	else if ( strcmp(argv[1],"-COE8") == 0)
	{
		for ( int i=0; i<2; i++)
		{
			romc[i] = path + romc[i];
		}
		
	rom[0].open(romc[0].c_str());
    rom[1].open(romc[1].c_str());
	}
		
	else if ( (strcmp(argv[1],"-IN8") == 0) || (strcmp(argv[1],"-IN32") == 0) || (strcmp(argv[1],"-COE32") == 0) || (strcmp(argv[1],"-MIF32") == 0))
	{	
	rom[0].open(argv[3]);
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
		rom[0] << ini;
		rom[1] << ini;
		rom[2] << ini;
		rom[3] << ini;
	}
	
	else if ( strcmp(argv[1],"-XMIF") == 0)
	{
		//rom[0] << ini;
		//rom[1] << ini;
	}
	
	else if ( strcmp(argv[1],"-COE8") == 0)
	{
		rom[0] << cini;
		rom[1] << cini;
	}
	
	else if ( strcmp(argv[1],"-COE32") == 0)
	{
	}

	else if ( strcmp(argv[1],"-MIF32") == 0)
	{
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
										rom[0] << hex << ROM4x1ADDR(address) << " : " << line.substr(9+i,2) << ";" << endl;
									break;
									case 1:
										rom[1] << hex << ROM4x1ADDR(address) << " : " << line.substr(9+i,2) << ";" << endl;               
									break;
									case 2:
										rom[2] << hex << ROM4x1ADDR(address) << " : " << line.substr(9+i,2) << ";" << endl;               
									break;
									case 3:
										rom[3] << hex << ROM4x1ADDR(address) << " : " << line.substr(9+i,2) << ";" << endl;               
									break;
									default:
									break;
								}
							}
							else if ( strcmp(argv[1],"-IN8") == 0)
							{
								rom[0] << line.substr(9+i,2) << endl;
							}
							
							else if ( strcmp(argv[1],"-XMIF") == 0)
							{
								switch ( bcount)
								{
									case 0:
										rom[0] << hex << line.substr(9+i,2) << endl;
									break;
									case 1:
										rom[0] << hex << line.substr(9+i,2) << endl;
									break;
									case 2:
										rom[1] << hex << line.substr(9+i,2) << endl;
									break;
									case 3:
										rom[1] << hex << line.substr(9+i,2) << endl;
									break;
									default:
									break;
								}
							}
							
							else if ( strcmp(argv[1],"-COE8") == 0)
							{
								switch ( bcount)
								{
									case 0:
									if ( xcoei==false)
									{
										rom[0] << "," << endl;
									}
										rom[0] << hex << line.substr(9+i,2);
										xcoei=false;
									break;
									case 1:
									if ( xcoei==false)
									{
										rom[0] << "," << endl;
									}
										rom[0] << hex << line.substr(9+i,2);
									xcoei=false;
									break;
									case 2:
									if ( xcoeii==false)
									{
										rom[1] << "," << endl;
									}
										rom[1] << hex << line.substr(9+i,2);
									xcoeii=false;
									break;
									case 3:
									if ( xcoeii==false)
									{
										rom[1] << "," << endl;
									}
										rom[1] << hex << line.substr(9+i,2);
									xcoeii=false;
									break;
									default:
									break;
								}
							}

							else if ( (strcmp(argv[1],"-IN32") == 0) || (strcmp(argv[1],"-COE32") == 0) || (strcmp(argv[1],"-MIF32") == 0))
							{
								int nn=0;
								
								unsigned char data=0;
								from_string(nn,line.substr(9+i,2),hex);
								data=static_cast<unsigned char>(nn);
								MEM.insertValue( address, data);
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
        rom[0] << fini;
        rom[1] << fini;
        rom[2] << fini;
        rom[3] << fini;
		
		rom[0].close();
		rom[1].close();
		rom[2].close();
		rom[3].close();
    }
	
	else if ( strcmp(argv[1],"-IN8") == 0)
	{
		rom[0].close();
    }
	
	else if ( strcmp(argv[1],"-IN32") == 0)
	{
		MEM.printIN( rom[0]);
		rom[0].close();
    }
	
	else if ( strcmp(argv[1],"-XMIF") == 0)
	{
		rom[0].close();
		rom[1].close();
    }

	else if ( strcmp(argv[1],"-MIF32") == 0)
	{
		MEM.printMIF( rom[0]);
		rom[0].close();
    }

	else if ( strcmp(argv[1],"-COE8") == 0)
	{
		rom[0] << cfini;
		rom[1] << cfini;
		rom[0].close();
		rom[1].close();
    }
	
	else if ( strcmp(argv[1],"-COE32") == 0)
	{
		MEM.printCOE( rom[0]);
		rom[0].close();
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
