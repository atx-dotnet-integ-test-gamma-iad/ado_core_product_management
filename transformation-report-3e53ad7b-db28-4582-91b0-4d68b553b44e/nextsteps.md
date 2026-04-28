# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important at this stage.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element reflects the intended cross-platform .NET version (e.g., `net8.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review code manually for any APIs that may behave differently or be unavailable on non-Windows platforms. Pay particular attention to:

- `System.Windows.Forms` or `System.Drawing` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop (`DllImport` with Windows-only DLLs)

If cross-platform support is required, these areas will need remediation.

## 6. Run on Target Platforms

If the goal is cross-platform support, run and test the application on each target operating system (Windows, Linux, macOS) to surface any runtime issues that static analysis may not catch:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`.

Review the publish output directory to confirm all required assets are present before deployment.