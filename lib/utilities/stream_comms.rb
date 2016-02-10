require 'json'
require 'base64'
module Paidgeeks

  # Get next object from stream. Stream must consist of Paidgeeks.encode()ed
  # objects that are separated by newlines. This function will not block.
  # Parameters:
  # - stream => The IO object that the object will be read from
  # Returns:
  # - An object from Paidgeeks.decode
  def self.read_object(stream)
    decode(read_line(stream,0))
  end

  # Write an objec to a stream using Paidgeeks.encode()
  # Parameters:
  # - stream => The IO object that will be written to, objects will be 
  #   separated with newline characters. The stream will not be flushed
  #   by this function.
  # - object => The object to serialize. Only data will be serialized.
  def self.write_object(stream, object)
    stream.write("#{encode(object)}\n")
  end
  # Encode an object.
  # This will encode an object as a string so that 
  # there will be no CR or LFs in the string.
  # Parameters:
  # - object => The object to encode, will only have its data fields encoded
  # Returns:
  # - string => Encoded object that Paidgeeks.decode will parse
  def self.encode object
    Base64.strict_encode64(JSON.generate(object))
  end

  # Decode an object.
  # This will decode an object that has been encoded with Paidgeeks.encode
  # Returns:
  # - The decoded object (data fields only!)
  def self.decode string
    JSON.parse(Base64.strict_decode64(string))
  end

  # Get a line of text within timeout seconds or return nil. Raise EOFError if stream closed 
  def self.read_line(stream, timeout)
    data = nil
    begin
      raise EOFError.new() if stream.closed?
      return nil if IO.select([stream], [], [], timeout).nil?
      data = stream.gets("\n")
    rescue IO::WaitReadable
      retry
    end
    data
  end
end
