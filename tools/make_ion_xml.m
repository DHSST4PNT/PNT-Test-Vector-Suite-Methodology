function make_ion_xml(iq_filename, sample_frequency_hz, sample_format, destination_file)
    % Create an ION RF metadata file from a template.
    %
    % Parameters:
    % iq_filename: Path to the IQ binary file relative to the metadata file.
    % sample_frequency_hz: Sample frequency in Hz.
    % sample_format: one of either 'int16' or 'float' for int16
    %                or float32 samples, respectively
    % destination_file: Path to the output metadata file.

	% NOTICE
	% The Homeland Security Act of 2002 (Section 305 of PL 107-296, as codified in 6 U.S.C. 185),
	% herein referred to as the “Act,” authorizes the Secretary of the U.S. Department of 
	% Homeland Security (DHS), acting through the DHS Under Secretary for Science and Technology, 
	% to establish one or more federally funded research and development centers (FFRDCs) 
	% to provide independent analysis of homeland security issues. MITRE Corporation operates 
	% the Homeland Security Systems Engineering and Development Institute (HSSEDI) as an FFRDC 
	% for DHS S&T under contract 70RSAT20D00000001. 

	% The HSSEDI FFRDC provides the government with the necessary systems engineering and 
	% development expertise to conduct complex acquisition planning and development; concept 
	% exploration, experimentation and evaluation; information technology, communications 
	% and cyber security processes, standards, methodologies and protocols; systems 
	% architecture and integration; quality and performance review, best practices and 
	% performance measures and metrics; and independent test and evaluation activities. 
	% The HSSEDI FFRDC also works with and supports other federal, state, local, tribal, 
	% public and private sector organizations that make up the homeland security enterprise. 
	% The HSSEDI FFRDC’s research is undertaken by mutual consent with DHS and is 
	% organized as a set of discrete tasks. This report presents the results of research 
	% and analysis conducted under:

	% Task Order 70RSAT20FR0000062
	% DHS S&T Next Generation Resilient PNT
	% The results presented in this report do not necessarily reflect official DHS opinion or policy. 

	% Approved for public release, Case Number 23-4096 / 70RSAT23FR-067-13
    dom = xmlread('base_metadata.xml');

    walk_path(dom, {'metadata', 'file', 'url', '#text'}) ...
        .setNodeValue(iq_filename);
    walk_path(dom, {'metadata', 'lane', 'system', 'freqbase', '#text'}) ...
        .setNodeValue(sample_frequency_hz);

    switch lower(sample_format)
        case 'int16'
            walk_path(dom, {'metadata', 'lane', 'block', 'chunk', 'lump', ...
                'stream','packedbits', '#text'}).setNodeValue('32');
            walk_path(dom, {'metadata', 'lane', 'block', 'chunk', 'lump', ...
                'stream','encoding', '#text'}).setNodeValue('TC');
            walk_path(dom, {'metadata', 'lane', 'block', 'chunk', 'lump', ...
                'stream','quantization', '#text'}).setNodeValue('16');
        case 'float'
            walk_path(dom, {'metadata', 'lane', 'block', 'chunk', 'lump', ...
                'stream','packedbits', '#text'}).setNodeValue('64');
            walk_path(dom, {'metadata', 'lane', 'block', 'chunk', 'lump', ...
                'stream','encoding', '#text'}).setNodeValue('FP');
            walk_path(dom, {'metadata', 'lane', 'block', 'chunk', 'lump', ...
                'stream','quantization', '#text'}).setNodeValue('32');
        otherwise
            error('Unsupported output sample format %s', sample_format);
    end

    xmlwrite(destination_file, dom);
end

function out = walk_path(parent_node, path)
    % Recursively get a series of XML child nodes by name.
    %
    % Parameters:
    % parent_node: An XML node.
    % path: A cell array of child node names.
    %
    % Returns:
    % An XML node.
    out = parent_node;
    for i=1:numel(path)
        out = get_child(out, path{i});
    end
end

function out = get_child(parent_node, name)
    % Get an XML child node by name.
    %
    % Parameters:
    % parent_node: An XML node.
    % name: A string name of a child XML node.
    %
    % Returns:
    % An XML node.
    if ~parent_node.hasChildNodes()
        throw(MException( ...
            'IQGenerator:XMLError', 'An error occured parsing XML.'));
    end
    children = parent_node.getChildNodes();
    n = children.getLength();
    found = false;
    for i=0:n-1
        child = children.item(i);
        if strcmp(child.getNodeName(), name)
            out = child;
            found = true;
            break
        end
    end
    if ~found
        throw(MException( ...
            'IQGenerator:XMLError', ...
            'Could not find XML child with name [%s].', name));
    end
end
