# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version you have installed. Run the following to confirm your SDK:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages previously targeted `net4x` or `netstandard`, verify their cross-platform compatibility on [NuGet.org](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no errors in the restored state:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate areas of the code that may behave differently on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures that did not exist in the legacy project should be investigated, as they may indicate platform-specific behavioral differences.

## 5. Check for Windows-Specific API Usage

Even without build errors, runtime failures can occur if the code uses Windows-specific APIs such as:

- `System.Windows.Forms` or `System.Drawing` (GDI+)
- The Windows Registry (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslashes, drive letters)
- COM interop or P/Invoke calls targeting Windows DLLs

Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) or search the codebase manually for these patterns.

## 6. Test on Target Platform

If the goal is cross-platform support, run the application on each target operating system (e.g., Linux, macOS) to surface any runtime issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

The output will be placed in the `bin/Release/{tfm}/publish/` directory and can be distributed or deployed from there.