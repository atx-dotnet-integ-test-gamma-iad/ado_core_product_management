# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been deprecated.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate areas of the code that may behave differently under the new runtime.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures after migration often point to platform-specific behavior differences, changed default values, or removed APIs.

## 5. Verify Runtime Behavior on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) and confirm expected behavior. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Case sensitivity in file system operations on Linux
- Any use of Windows-specific registry, COM interop, or P/Invoke calls that may not function on non-Windows platforms

## 6. Review Removed or Changed APIs

Check the code for any use of APIs that were available in .NET Framework but have changed behavior or been removed in .NET. Microsoft provides a compatibility analyzer that can assist:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Run the build again after adding the analyzer and review any new diagnostics.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Review the contents of the publish output directory to confirm all required assets are present before deploying to the target environment.