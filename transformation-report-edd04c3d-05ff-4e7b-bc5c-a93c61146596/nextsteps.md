# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages. If any packages were previously Windows-only (e.g., certain `System.Data` or `Microsoft.Win32` packages), confirm their cross-platform equivalents are in place.

## 3. Build the Solution

Perform a clean build to confirm there are no issues beyond what was reported:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, obsolete APIs, or platform compatibility annotations (`CA1416`).

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test output carefully. Failures may indicate runtime behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, even when the build succeeds.

## 5. Validate Platform-Specific Code

Since this is a cross-platform migration, audit the codebase for any APIs that are Windows-specific. You can use the .NET Compatibility Analyzer to assist:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to:
- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing` (GDI+) usage
- COM interop or P/Invoke calls targeting Windows DLLs
- `AppDomain` usage that behaves differently in .NET 5+

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target platform. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. Review the contents of the `./publish` directory to confirm all required files are present before deploying.