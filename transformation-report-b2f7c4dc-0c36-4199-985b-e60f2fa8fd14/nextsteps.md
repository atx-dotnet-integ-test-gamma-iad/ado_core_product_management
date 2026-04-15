# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no configuration-specific issues:

```bash
dotnet build --configuration Release
```

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests to determine whether they indicate regressions introduced during the migration or pre-existing issues.

## 5. Check for Platform-Specific API Usage

Even without build errors, the code may reference APIs that are Windows-specific and will fail at runtime on other platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages such as:
- `System.Windows.Forms`
- `System.Drawing` (without the `System.Drawing.Common` NuGet package)
- `Microsoft.Win32` registry APIs
- P/Invoke calls to Windows-specific native libraries

## 6. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime-only issues:

```bash
dotnet run --configuration Release
```

Note any exceptions or behavioral differences across platforms.

## 7. Publish the Application

Once validation is complete, publish the application for the desired target runtime. For a self-contained, platform-specific publish:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (RID) for your target environment, such as `win-x64` or `osx-x64`. A list of supported RIDs can be found in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

For a framework-dependent publish (requires .NET runtime installed on the target machine):

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

## 8. Review Output Artifacts

After publishing, inspect the output directory (typically `bin/Release/net8.0/<rid>/publish/`) to confirm all required files, configuration files, and assets are present.