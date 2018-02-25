require 'xcodeproj'

#工程路径
# $project_path = '/Users/hb/Desktop/xSimple备份/2017-03-22-Ruby/ios_3.0/baseApp/CORProject/KndCRMv2.xcodeproj'
# path = '/Users/hb/Desktop/xSimple备份/2017-03-22-Ruby/ios_3.0/baseApp/CORModules/ModuleThirdPay';
# 外部传入的工程路径
 $project_path       = "/xpackage/#{$*[0]}/ios/code/CorMobiApp.xcodeproj";
#path = "CorMobiApp.xcodeproj"
# if path.empty? then puts "没有找到iOS项目，请检查目录文件" end
#$project_path = Dir::pwd + "/" + path
puts "项目路径       = #{$project_path}"
$plugin_folder        = 'CORModules'
puts "插件文件件名称  = #{$plugin_folder}"
# 外部传入的原生插件文件夹名称
$folderName          = $*[1];
puts "插件文件夹名称  = #{$folderName}"

#获取项目
$project = Xcodeproj::Project.open($project_path);
#获取target
$target = $project.targets.first
# 获取插件目录的group，如果不存在则创建
$group_One = $project[$plugin_folder] || $project.main_group.find_subpath(File.join('CorMobiApp',$plugin_folder), true);

puts "插件目录的group路劲      = #{$group_One.real_path.to_s}"

# 在目标目录新建group目录
$group = $group_One.find_subpath($folderName, true)
puts "group      = #{$group}"
$group.set_path($group_One.real_path.to_s + "/" + $folderName)

# 获取全部的文件引用
$file_ref_list = $target.source_build_phase.files_references

#获取所有静态库文件引用
$framework_ref_list = $target.frameworks_build_phases.files_references

# 获取所有资源文件引用
$bundle_ref_list = $target.resources_build_phase.files_references

#当前项目中所有动态库
$embed_framework = nil;

$target.copy_files_build_phases.each do |copy_build_phases|
   if copy_build_phases.name == "Embed Frameworks"
       $embed_framework = copy_build_phases;
   end
end

puts "dong tai ku == #{$embed_framework_list}"

# 设置文件引用是否存在标识
$file_ref_mark = false
#当前添加库是否为动态库
$isEmbed = false;

# 检测需要添加的文件节点是否存在
def detectionFileExists (fileName)

    if fileName.to_s.end_with?(".framework" ,".a")
        for file_ref_temp in $framework_ref_list
            if file_ref_temp.path.to_s.end_with?(fileName) then
                # $file_ref_mark = true;
                return true;
                break;
            end
        end

    elsif fileName.to_s.end_with?(".plist" ,".bundle",".xml",".png",".xib",".strings")
        for file_ref_temp in $bundle_ref_list
            if file_ref_temp.path.to_s.end_with?(fileName) then
                # $file_ref_mark = true;
                return true;

            end
        end
    elsif fileName.to_s.include?("__MACOSX")
 
            return true;
    else
        for file_ref_temp in $file_ref_list
            if file_ref_temp.path.to_s.end_with?(fileName) then
                # $file_ref_mark = true;
                return true;
            end
            end
    end



end

# 添加文件xcode工程
def addFilesToGroup(aproject,aTarget,aGroup)
    
    puts "Group-path : #{aGroup.real_path.to_s}"
    
    
    Dir.foreach (aGroup.real_path) do |entry|
        filePath = File.join(aGroup.real_path,entry);

        # 判断文件是否是以.或者.DS_Store结尾，如果是则执行下一个循环
        if entry.to_s.end_with?(".") or entry.to_s.end_with?(".DS_Store") or entry.to_s == "info.xml" or entry.to_s == "IDE" or entry.to_s == ".svn" or entry.to_s == "__MACOSX"
            next;
        end
        
        # 判断文件节点是否存在
        $file_ref_mark = detectionFileExists(entry);
        # 如果当前文件节点存在则执行下一个
        if $file_ref_mark == true
            next
        end

        puts " aGroup 路径 = #{aGroup}"
        
        # 判断文件是否为framework或者.a静态库
        if filePath.to_s.end_with?(".framework" ,".a")
            fileReference = aGroup.new_reference(filePath);
            build_phase = aTarget.frameworks_build_phase;
            build_phase.add_file_reference(fileReference);
            if $isEmbed == true
                #添加动态库
                $embed_framework.add_file_reference(fileReference)
            end

        # 如果文件问bundle文件
        elsif filePath.to_s.end_with?(".bundle",".plist" ,".xml",".png",".xib",".js",".html",".css",".strings")
            fileReference = aGroup.new_reference(filePath);
            aTarget.resources_build_phase.add_file_reference(fileReference, true)
        # 如果路径不为文件夹
        elsif filePath.to_s.end_with?("pbobjc.m", "pbobjc.mm") then
            fileReference = aGroup.new_reference(filePath);
            aTarget.add_file_references([fileReference], '-fno-objc-arc')

        elsif filePath.to_s.end_with?(".m", ".mm", ".cpp") then
            fileReference = aGroup.new_reference(filePath);
            aTarget.source_build_phase.add_file_reference(fileReference, true)

        elsif File.directory?(filePath)
            subGroup = aGroup.new_group(entry);
            subGroup.set_source_tree(aGroup.source_tree)
            group_Path = aGroup.real_path.to_s + "/" + entry;
            subGroup.set_path(group_Path )
            if entry == "embed"
                puts "dong tai ku"
                $isEmbed = true;
            end
            addFilesToGroup(aproject, aTarget, subGroup)
            $isEmbed = false;
        end
    end
end

puts '正在添加静态库引用'
addFilesToGroup($project ,$target ,$group);
puts '库引用添加完成'
$project.save;
puts 'pbxproj文件保存成功'
