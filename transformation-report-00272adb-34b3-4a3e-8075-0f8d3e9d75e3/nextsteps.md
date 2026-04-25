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

Review the output for any warnings about deprecated packages or packages that may have been replaced during the transformation.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no errors or warnings that were not present during the initial transformation check:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review the code for usage of the following:

- `System.Windows.Forms` or `System.Drawing` (GDI+)
- `Microsoft.Win32` registry APIs
- COM interop or P/Invoke calls targeting Windows-only native libraries
- `AppDomain` APIs with limited cross-platform support

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues statically.

## 6. Validate Runtime Behavior

Run the application and exercise its primary workflows. Pay particular attention to:

- File path handling, as `Path.DirectorySeparatorChar` differs between Windows and Unix systems.
- Configuration file loading, particularly if the project previously relied on `app.config` or `web.config` transforms.
- Database connectivity if ADO.NET is in use (as suggested by the project name `AdoCore`), confirming that the correct driver packages are referenced and connection strings are valid.

## 7. Publish the Application

Once runtime behavior is validated, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate RID, for example:

| Platform | RID |
|---|---|
| Windows x64 | `win-x64` |
| Linux x64 | `linux-x64` |
| macOS x64 | `osx-x64` |

Review the contents of the publish output directory to confirm all required assets and dependencies are present before deploying to the target environment.